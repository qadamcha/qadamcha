import 'package:flutter/foundation.dart';
import '../../data/datasources/chat_local_datasource.dart';

enum AiChatStatus { initial, loading, loaded, error }

/// UI da ko'rsatiladigan xabar modeli
@immutable
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final int tokenCount;
  final bool isError;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.tokenCount = 0,
    this.isError = false,
  });

  /// DB modeldan yaratish
  factory ChatMessage.fromModel(ChatMessageModel model) {
    return ChatMessage(
      text: model.text,
      isUser: model.isUser,
      timestamp: model.timestamp,
      tokenCount: model.tokenCount,
    );
  }

  /// DB modelga o'girish
  ChatMessageModel toModel() {
    return ChatMessageModel(
      text: text,
      isUser: isUser,
      timestamp: timestamp,
      tokenCount: tokenCount,
    );
  }
}

/// Chat sessiya xulosa modeli (ro'yxat uchun)
@immutable
class ChatSessionSummary {
  final String id;
  final String title;
  final String lastMessage;
  final DateTime updatedAt;

  const ChatSessionSummary({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.updatedAt,
  });

  factory ChatSessionSummary.fromModel(ChatSessionModel model) {
    return ChatSessionSummary(
      id: model.id,
      title: model.title,
      lastMessage: model.lastMessageText,
      updatedAt: model.updatedAt,
    );
  }
}

@immutable
class AiChatState {
  final List<ChatMessage> messages;
  final List<ChatSessionSummary> chatSessions;
  final AiChatStatus status;
  final bool isAiOnline;
  final String? errorMessage;
  final String? currentSessionId;
  final int totalTokens;
  /// Oxirgi muvaffaqiyatsiz xabar — retry uchun
  final String? lastFailedMessage;
  final String? lastFailedChildId;

  const AiChatState({
    this.messages = const [],
    this.chatSessions = const [],
    this.status = AiChatStatus.initial,
    this.isAiOnline = false,
    this.errorMessage,
    this.currentSessionId,
    this.totalTokens = 0,
    this.lastFailedMessage,
    this.lastFailedChildId,
  });

  bool get canRetry => lastFailedMessage != null && status == AiChatStatus.error;

  AiChatState copyWith({
    List<ChatMessage>? messages,
    List<ChatSessionSummary>? chatSessions,
    AiChatStatus? status,
    bool? isAiOnline,
    String? errorMessage,
    String? currentSessionId,
    int? totalTokens,
    String? lastFailedMessage,
    String? lastFailedChildId,
    bool clearLastFailed = false,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      chatSessions: chatSessions ?? this.chatSessions,
      status: status ?? this.status,
      isAiOnline: isAiOnline ?? this.isAiOnline,
      errorMessage: errorMessage,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      totalTokens: totalTokens ?? this.totalTokens,
      lastFailedMessage: clearLastFailed ? null : (lastFailedMessage ?? this.lastFailedMessage),
      lastFailedChildId: clearLastFailed ? null : (lastFailedChildId ?? this.lastFailedChildId),
    );
  }
}
