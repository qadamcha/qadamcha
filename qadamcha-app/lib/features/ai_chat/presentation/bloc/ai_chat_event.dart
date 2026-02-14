import 'package:flutter/foundation.dart';

@immutable
abstract class AiChatEvent {
  const AiChatEvent();
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

/// Chat tarixini tozalash
class ClearChatEvent extends AiChatEvent {
  const ClearChatEvent();
}
