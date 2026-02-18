import 'package:flutter/foundation.dart';

@immutable
abstract class AiChatEvent {
  const AiChatEvent();
}

/// Barcha chatlar ro'yxatini yuklash
class LoadAllChatsEvent extends AiChatEvent {
  const LoadAllChatsEvent();
}

/// Mavjud chatni yuklash
class LoadChatEvent extends AiChatEvent {
  final String sessionId;
  const LoadChatEvent({required this.sessionId});
}

/// Yangi chat yaratish
class CreateNewChatEvent extends AiChatEvent {
  const CreateNewChatEvent();
}

/// Chatni o'chirish
class DeleteChatEvent extends AiChatEvent {
  final String sessionId;
  const DeleteChatEvent({required this.sessionId});
}

/// Foydalanuvchi xabar yubordi
class SendMessageEvent extends AiChatEvent {
  final String message;
  final String? childId;
  const SendMessageEvent({required this.message, this.childId});
}

/// AI xizmat holatini tekshirish
class CheckAiStatusEvent extends AiChatEvent {
  const CheckAiStatusEvent();
}
