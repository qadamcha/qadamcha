import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import 'ai_chat_event.dart';
import 'ai_chat_state.dart';

class AiChatBloc extends Bloc<AiChatEvent, AiChatState> {
  final AiChatRepository _repository;

  AiChatBloc({required AiChatRepository repository})
      : _repository = repository,
        super(AiChatState(
          messages: [
            ChatMessage(
              text: 'Assalomu alaykum! Men Qadamcha AI maslahatchiman. '
                  'Farzand tarbiyasi, rivojlanishi va sog\'lig\'i bo\'yicha '
                  'savollaringizga javob beraman. Qanday yordam bera olaman? 😊',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          ],
        )) {
    on<SendMessageEvent>(_onSendMessage);
    on<CheckAiStatusEvent>(_onCheckStatus);
    on<ClearChatEvent>(_onClearChat);
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<AiChatState> emit,
  ) async {
    // Foydalanuvchi xabarini qo'shish
    final userMessage = ChatMessage(
      text: event.message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    emit(state.copyWith(
      messages: [...state.messages, userMessage],
      status: AiChatStatus.loading,
    ));

    try {
      final response = await _repository.sendMessage(
        message: event.message,
        childId: event.childId,
      );

      final aiMessage = ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      emit(state.copyWith(
        messages: [...state.messages, aiMessage],
        status: AiChatStatus.loaded,
      ));
    } catch (e) {
      final errorMessage = ChatMessage(
        text: 'Kechirasiz, hozir javob bera olmayapman. '
            'Internet aloqangizni tekshiring va qayta urinib ko\'ring.',
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

  void _onClearChat(ClearChatEvent event, Emitter<AiChatState> emit) {
    emit(AiChatState(
      isAiOnline: state.isAiOnline,
      messages: [
        ChatMessage(
          text: 'Assalomu alaykum! Men Qadamcha AI maslahatchiman. '
              'Farzand tarbiyasi, rivojlanishi va sog\'lig\'i bo\'yicha '
              'savollaringizga javob beraman. Qanday yordam bera olaman? 😊',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
    ));
  }
}
