import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/chat_local_datasource.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import 'ai_chat_event.dart';
import 'ai_chat_state.dart';

/// Context token limiti (~500K)
const int _maxContextTokens = 400000;

class AiChatBloc extends Bloc<AiChatEvent, AiChatState> {
  final AiChatRepository _repository;
  final ChatLocalDataSource _localDataSource;

  AiChatBloc({
    required AiChatRepository repository,
    required ChatLocalDataSource localDataSource,
  })  : _repository = repository,
        _localDataSource = localDataSource,
        super(const AiChatState()) {
    on<LoadAllChatsEvent>(_onLoadAllChats);
    on<LoadChatEvent>(_onLoadChat);
    on<CreateNewChatEvent>(_onCreateNewChat);
    on<DeleteChatEvent>(_onDeleteChat);
    on<SendMessageEvent>(_onSendMessage);
    on<CheckAiStatusEvent>(_onCheckStatus);
  }

  /// Barcha chatlar ro'yxatini yuklash
  Future<void> _onLoadAllChats(
    LoadAllChatsEvent event,
    Emitter<AiChatState> emit,
  ) async {
    final sessions = await _localDataSource.getAllSessions();
    final summaries = sessions
        .map((s) => ChatSessionSummary.fromModel(s))
        .toList();

    emit(state.copyWith(chatSessions: summaries));
  }

  /// Mavjud chatni yuklash
  Future<void> _onLoadChat(
    LoadChatEvent event,
    Emitter<AiChatState> emit,
  ) async {
    final session = await _localDataSource.getSession(event.sessionId);
    if (session == null) return;

    final messages = session.messages
        .map((m) => ChatMessage.fromModel(m))
        .toList();

    emit(state.copyWith(
      currentSessionId: event.sessionId,
      messages: messages,
      totalTokens: session.totalTokens,
      status: AiChatStatus.loaded,
    ));
  }

  /// Yangi chat yaratish
  Future<void> _onCreateNewChat(
    CreateNewChatEvent event,
    Emitter<AiChatState> emit,
  ) async {
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    final session = ChatSessionModel(
      id: sessionId,
      title: 'Yangi suhbat',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _localDataSource.saveSession(session);

    // Welcome xabari
    final welcomeMessage = ChatMessage(
      text: 'Assalomu alaykum! Men Qadamcha AI maslahatchiman. '
          'Farzand tarbiyasi, rivojlanishi va sog\'lig\'i bo\'yicha '
          'savollaringizga javob beraman. Qanday yordam bera olaman? 😊',
      isUser: false,
      timestamp: DateTime.now(),
    );

    // Welcome xabarni DB ga ham saqlash
    await _localDataSource.addMessage(sessionId, welcomeMessage.toModel());

    // Sessiyalar ro'yxatini yangilash
    final sessions = await _localDataSource.getAllSessions();
    final summaries = sessions
        .map((s) => ChatSessionSummary.fromModel(s))
        .toList();

    emit(state.copyWith(
      currentSessionId: sessionId,
      messages: [welcomeMessage],
      chatSessions: summaries,
      totalTokens: 0,
      status: AiChatStatus.loaded,
    ));
  }

  /// Chatni o'chirish
  Future<void> _onDeleteChat(
    DeleteChatEvent event,
    Emitter<AiChatState> emit,
  ) async {
    await _localDataSource.deleteSession(event.sessionId);

    // Agar hozirgi chat o'chirilsa, xabarlarni tozalash
    final isCurrent = state.currentSessionId == event.sessionId;

    // Ro'yxatni yangilash
    final sessions = await _localDataSource.getAllSessions();
    final summaries = sessions
        .map((s) => ChatSessionSummary.fromModel(s))
        .toList();

    emit(state.copyWith(
      chatSessions: summaries,
      messages: isCurrent ? const [] : null,
      currentSessionId: isCurrent ? '' : null,
      totalTokens: isCurrent ? 0 : null,
    ));
  }

  /// Xabar yuborish — context bilan
  /// FIX #2: Race condition yo'q — session yaratishni to'g'ridan-to'g'ri shu methoda qiladi
  /// FIX #3: History faqat OLDINGI xabarlardan tuziladi, hozirgi xabar history'ga kiritilmaydi
  ///         (backend o'zi `message` ni history oxiriga qo'shadi)
  /// FIX #5: User xabari history'da DUPLICATE bo'lmaydi
  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<AiChatState> emit,
  ) async {
    // FIX #2: Agar session yo'q bo'lsa, SINHRON yaratish (add() emas)
    String sessionId = state.currentSessionId ?? '';
    if (sessionId.isEmpty) {
      sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      final session = ChatSessionModel(
        id: sessionId,
        title: 'Yangi suhbat',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _localDataSource.saveSession(session);

      emit(state.copyWith(
        currentSessionId: sessionId,
        messages: const [],
        totalTokens: 0,
      ));
    }

    // Foydalanuvchi xabarini qo'shish
    final userMessage = ChatMessage(
      text: event.message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    // FIX #3 & #5: History ni OLDINGI xabarlardan yaratish
    // (user xabarini qo'SHMAYmiz, chunki backend o'zi qo'shadi)
    final history = _buildContextHistory(state.messages);

    // UI ga darhol qo'shish
    final updatedMessages = [...state.messages, userMessage];
    emit(state.copyWith(
      messages: updatedMessages,
      status: AiChatStatus.loading,
    ));

    // DB ga saqlash
    await _localDataSource.addMessage(sessionId, userMessage.toModel());

    try {
      final (response, tokenCount) = await _repository.sendMessage(
        message: event.message,
        childId: event.childId,
        history: history,
      );

      final aiMessage = ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
        tokenCount: tokenCount,
      );

      // DB ga saqlash
      await _localDataSource.addMessage(sessionId, aiMessage.toModel());

      // Sessiyalar ro'yxatini yangilash
      final sessions = await _localDataSource.getAllSessions();
      final summaries = sessions
          .map((s) => ChatSessionSummary.fromModel(s))
          .toList();

      final newTotal = state.totalTokens + tokenCount;

      emit(state.copyWith(
        messages: [...state.messages, aiMessage],
        status: AiChatStatus.loaded,
        totalTokens: newTotal,
        chatSessions: summaries,
      ));
    } catch (e) {
      // Timeout va network xatolarini alohida handle qilish
      String errorText;
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('timeout') || errorStr.contains('receivetimeout')) {
        errorText = 'AI javob berishi biroz ko\'proq vaqt oldi. '
            'Iltimos, savolingizni qisqaroq qilib qayta yuboring yoki '
            'biroz kutib qayta urinib ko\'ring. ⏳';
      } else if (errorStr.contains('internet') || errorStr.contains('ulanib')) {
        errorText = 'Internet aloqangiz bilan muammo bor. '
            'Internetni tekshiring va qayta urinib ko\'ring. 📶';
      } else {
        errorText = 'Kechirasiz, hozir javob bera olmayapman. '
            'Qayta urinib ko\'ring.';
      }

      final errorMessage = ChatMessage(
        text: errorText,
        isUser: false,
        timestamp: DateTime.now(),
      );

      emit(state.copyWith(
        messages: [...state.messages, errorMessage],
        status: AiChatStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// AI holat tekshirish
  Future<void> _onCheckStatus(
    CheckAiStatusEvent event,
    Emitter<AiChatState> emit,
  ) async {
    try {
      final isOnline = await _repository.checkStatus();
      emit(state.copyWith(isAiOnline: isOnline));
    } catch (_) {
      emit(state.copyWith(isAiOnline: false));
    }
  }

  /// Sliding window — context uchun tarix yaratish
  /// 400K token limitdan oshsa, eng eski xabarlarni olib tashlash
  ///
  /// MUHIM: Bu methoda faqat OLDINGI xabarlarni qaytaradi.
  /// Hozirgi yangi user xabari SHU YERDA emas, backend o'zi
  /// `message` parametri orqali qo'shadi.
  List<Map<String, String>> _buildContextHistory(List<ChatMessage> messages) {
    // Welcome va error xabarlarini filtrlash
    final relevantMessages = messages.where((m) {
      // Bot welcome xabarmi?
      if (!m.isUser && m.text.startsWith('Assalomu alaykum! Men Qadamcha')) {
        return false;
      }
      // Error xabarmi?
      if (!m.isUser && (m.text.contains('javob bera olmayapman') ||
          m.text.contains('vaqt oldi') ||
          m.text.contains('Internet aloqangiz'))) {
        return false;
      }
      return true;
    }).toList();

    if (relevantMessages.isEmpty) return [];

    // Token hisobini OXIRIDAN boshlab hisoblash (eng yangi xabarlar muhimroq)
    int totalTokens = 0;
    int startIndex = relevantMessages.length;

    for (int i = relevantMessages.length - 1; i >= 0; i--) {
      // Taxminiy token hisob: har 4 belgi ≈ 1 token
      final estimatedTokens = (relevantMessages[i].text.length / 4).ceil();
      totalTokens += estimatedTokens;

      if (totalTokens > _maxContextTokens) {
        startIndex = i + 1;
        break;
      }
      startIndex = i;
    }

    // Sliding window — faqat limitga sig'adigan xabarlar
    final windowMessages = relevantMessages.sublist(startIndex);

    return windowMessages.map((m) => {
      'role': m.isUser ? 'user' : 'model',
      'text': m.text,
    }).toList();
  }
}
