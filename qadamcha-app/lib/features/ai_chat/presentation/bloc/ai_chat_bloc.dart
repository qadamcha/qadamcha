import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

  /// So'rovni bekor qilish uchun
  CancelToken? _activeCancelToken;

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
    on<RetryLastMessageEvent>(_onRetryLastMessage);
    on<CancelMessageEvent>(_onCancelMessage);
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
      clearLastFailed: true,
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
      clearLastFailed: true,
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
      clearLastFailed: isCurrent,
    ));
  }

  /// Xabar yuborish — yangilangan arxitektura
  /// - CancelToken bilan so'rovni bekor qilish mumkin
  /// - Error xabarlar DB ga saqlanmaydi
  /// - Retry uchun lastFailedMessage saqlanadi
  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<AiChatState> emit,
  ) async {
    // Agar oldingi so'rov hali ishlayotgan bo'lsa, bekor qilish
    _cancelActiveRequest();

    // Session yaratish (agar yo'q bo'lsa)
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

    // Foydalanuvchi xabarini yaratish
    final userMessage = ChatMessage(
      text: event.message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    // History ni OLDINGI xabarlardan yaratish
    // (faqat muvaffaqiyatli xabarlar — error xabarlar filtrlangan)
    final history = _buildContextHistory(state.messages);

    // UI ga darhol qo'shish + loading holat
    final updatedMessages = [...state.messages, userMessage];
    emit(state.copyWith(
      messages: updatedMessages,
      status: AiChatStatus.loading,
      clearLastFailed: true,
    ));

    // DB ga saqlash
    await _localDataSource.addMessage(sessionId, userMessage.toModel());

    // Yangi cancel token yaratish
    _activeCancelToken = CancelToken();

    try {
      final (response, tokenCount) = await _repository.sendMessage(
        message: event.message,
        childId: event.childId,
        history: history,
        cancelToken: _activeCancelToken,
      );

      _activeCancelToken = null;

      final aiMessage = ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
        tokenCount: tokenCount,
      );

      // AI javobni DB ga saqlash
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
        clearLastFailed: true,
      ));
    } catch (e) {
      _activeCancelToken = null;

      // Cancel qilingan so'rov — foydalanuvchiga xabar bermaymiz
      if (e is DioException && CancelToken.isCancel(e)) {
        emit(state.copyWith(
          status: AiChatStatus.loaded,
          clearLastFailed: true,
        ));
        return;
      }

      // Xato turini aniqlash
      String errorText;
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('timeout') || errorStr.contains('receivetimeout')) {
        errorText = 'AI javob berishi biroz ko\'proq vaqt oldi. '
            'Qayta urinib ko\'ring yoki savolingizni qisqaroq yozing. ⏳';
      } else if (errorStr.contains('internet') || errorStr.contains('ulanib')) {
        errorText = 'Internet aloqangiz bilan muammo bor. '
            'Internetni tekshiring va qayta urinib ko\'ring. 📶';
      } else {
        errorText = 'Kechirasiz, hozir javob bera olmayapman. '
            'Qayta urinib ko\'ring.';
      }

      // Error xabar — faqat UI da ko'rsatiladi, DB ga saqlanMAYDI
      final errorMessage = ChatMessage(
        text: errorText,
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      );

      emit(state.copyWith(
        messages: [...state.messages, errorMessage],
        status: AiChatStatus.error,
        errorMessage: e.toString(),
        lastFailedMessage: event.message,
        lastFailedChildId: event.childId,
      ));
    }
  }

  /// Oxirgi xato xabarni qayta yuborish
  Future<void> _onRetryLastMessage(
    RetryLastMessageEvent event,
    Emitter<AiChatState> emit,
  ) async {
    final failedMessage = state.lastFailedMessage;
    if (failedMessage == null) return;

    final childId = state.lastFailedChildId;

    // Error xabarni UI dan olib tashlash
    final cleanMessages = state.messages
        .where((m) => !m.isError)
        .toList();

    // Oxirgi user xabarini ham olib tashlash (qayta yuboriladi)
    if (cleanMessages.isNotEmpty && cleanMessages.last.isUser) {
      cleanMessages.removeLast();
    }

    // DB dan ham oxirgi user xabarni o'chirish (qayta yoziladi)
    // Aslida DB da error xabar yo'q (saqlanmagan), faqat user xabar bor

    emit(state.copyWith(
      messages: cleanMessages,
      clearLastFailed: true,
    ));

    // Qayta yuborish
    add(SendMessageEvent(message: failedMessage, childId: childId));
  }

  /// Hozirgi so'rovni bekor qilish
  Future<void> _onCancelMessage(
    CancelMessageEvent event,
    Emitter<AiChatState> emit,
  ) async {
    _cancelActiveRequest();

    emit(state.copyWith(
      status: AiChatStatus.loaded,
      clearLastFailed: true,
    ));
  }

  /// Aktiv so'rovni bekor qilish (ichki)
  void _cancelActiveRequest() {
    if (_activeCancelToken != null && !_activeCancelToken!.isCancelled) {
      _activeCancelToken!.cancel('Foydalanuvchi bekor qildi');
      _activeCancelToken = null;
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
  /// FIX: Error va welcome xabarlar filtrlangan.
  /// FIX: Map literal sintaksisi to'g'rilangan (<String, String>{...}).
  List<Map<String, String>> _buildContextHistory(List<ChatMessage> messages) {
    // Welcome, error xabarlarini filtrlash
    final relevantMessages = messages.where((m) {
      // Error xabarmi?
      if (m.isError) return false;
      // Bot welcome xabarmi?
      if (!m.isUser && m.text.startsWith('Assalomu alaykum! Men Qadamcha')) {
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

    return windowMessages.map((m) => <String, String>{
      'role': m.isUser ? 'user' : 'model',
      'text': m.text,
    }).toList();
  }

  @override
  Future<void> close() {
    _cancelActiveRequest();
    return super.close();
  }
}
