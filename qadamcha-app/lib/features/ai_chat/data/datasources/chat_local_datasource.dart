import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Chat session model — lokal saqlash uchun
class ChatSessionModel {
  final String id;
  String title;
  final DateTime createdAt;
  DateTime updatedAt;
  List<ChatMessageModel> messages;

  ChatSessionModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    List<ChatMessageModel>? messages,
  }) : messages = messages ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'messages': messages.map((m) => m.toJson()).toList(),
  };

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) {
    return ChatSessionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      messages: (json['messages'] as List<dynamic>?)
          ?.map((m) => ChatMessageModel.fromJson(m as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  /// Oxirgi xabar matni (ro'yxat uchun)
  String get lastMessageText {
    if (messages.isEmpty) return 'Yangi suhbat';
    return messages.last.text.length > 60
        ? '${messages.last.text.substring(0, 60)}...'
        : messages.last.text;
  }

  /// Jami token soni
  int get totalTokens {
    int total = 0;
    for (final msg in messages) {
      total += msg.tokenCount;
    }
    return total;
  }
}

/// Chat xabar model
class ChatMessageModel {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final int tokenCount;

  const ChatMessageModel({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.tokenCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
    'tokenCount': tokenCount,
  };

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      tokenCount: (json['tokenCount'] as int?) ?? 0,
    );
  }

  /// Backend history uchun format
  Map<String, String> toHistoryItem() => {
    'role': isUser ? 'user' : 'model',
    'text': text,
  };
}

/// Chat Local DataSource — SharedPreferences orqali saqlash
abstract class ChatLocalDataSource {
  Future<List<ChatSessionModel>> getAllSessions();
  Future<ChatSessionModel?> getSession(String sessionId);
  Future<void> saveSession(ChatSessionModel session);
  Future<void> deleteSession(String sessionId);
  Future<void> addMessage(String sessionId, ChatMessageModel message);
  Future<void> updateSessionTitle(String sessionId, String title);
}

class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  final SharedPreferences _prefs;
  static const String _sessionsKey = 'ai_chat_sessions';

  ChatLocalDataSourceImpl(this._prefs);

  @override
  Future<List<ChatSessionModel>> getAllSessions() async {
    final jsonStr = _prefs.getString(_sessionsKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonStr) as List<dynamic>;
      final sessions = jsonList
          .map((j) => ChatSessionModel.fromJson(j as Map<String, dynamic>))
          .toList();
      // Eng yangi birinchi
      sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return sessions;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<ChatSessionModel?> getSession(String sessionId) async {
    final sessions = await getAllSessions();
    try {
      return sessions.firstWhere((s) => s.id == sessionId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveSession(ChatSessionModel session) async {
    final sessions = await getAllSessions();
    final index = sessions.indexWhere((s) => s.id == session.id);

    if (index >= 0) {
      sessions[index] = session;
    } else {
      sessions.insert(0, session);
    }

    await _saveSessions(sessions);
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    final sessions = await getAllSessions();
    sessions.removeWhere((s) => s.id == sessionId);
    await _saveSessions(sessions);
  }

  @override
  Future<void> addMessage(String sessionId, ChatMessageModel message) async {
    final sessions = await getAllSessions();
    final index = sessions.indexWhere((s) => s.id == sessionId);

    if (index >= 0) {
      sessions[index].messages.add(message);
      sessions[index].updatedAt = DateTime.now();

      // Agar birinchi user xabari bo'lsa, sarlavhani yangilash
      if (sessions[index].title == 'Yangi suhbat' && message.isUser) {
        sessions[index].title = message.text.length > 40
            ? '${message.text.substring(0, 40)}...'
            : message.text;
      }

      await _saveSessions(sessions);
    }
  }

  @override
  Future<void> updateSessionTitle(String sessionId, String title) async {
    final sessions = await getAllSessions();
    final index = sessions.indexWhere((s) => s.id == sessionId);
    if (index >= 0) {
      sessions[index].title = title;
      await _saveSessions(sessions);
    }
  }

  Future<void> _saveSessions(List<ChatSessionModel> sessions) async {
    final jsonStr = json.encode(sessions.map((s) => s.toJson()).toList());
    await _prefs.setString(_sessionsKey, jsonStr);
  }
}
