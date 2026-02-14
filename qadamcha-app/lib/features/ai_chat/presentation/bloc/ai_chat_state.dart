import 'package:flutter/foundation.dart';

enum AiChatStatus { initial, loading, loaded, error }

@immutable
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

@immutable
class AiChatState {
  final List<ChatMessage> messages;
  final AiChatStatus status;
  final bool isAiOnline;
  final String? errorMessage;

  const AiChatState({
    this.messages = const [],
    this.status = AiChatStatus.initial,
    this.isAiOnline = false,
    this.errorMessage,
  });

  AiChatState copyWith({
    List<ChatMessage>? messages,
    AiChatStatus? status,
    bool? isAiOnline,
    String? errorMessage,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      status: status ?? this.status,
      isAiOnline: isAiOnline ?? this.isAiOnline,
      errorMessage: errorMessage,
    );
  }
}
