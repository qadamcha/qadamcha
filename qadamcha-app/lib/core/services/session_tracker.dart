/// SessionTracker — Bola menusida vaqt tracking uchun service
/// 
/// Stack-based: har bir sahifa alohida sessiya ochadi, alohida tugatadi.
/// child_home, content, games — hammasi bir vaqtda kuzatiladi.
class SessionTracker {
  SessionTracker._internal();
  static final SessionTracker instance = SessionTracker._internal();

  /// Har bir sessiya turi uchun alohida start vaqt
  final Map<String, DateTime> _sessions = {};

  /// Sessiya boshlash (oldingi sessiyani o'chirmaydi)
  void startSession(String type) {
    _sessions[type] = DateTime.now();
  }

  /// Sessiya tugatish va davomiylikni daqiqalarda qaytarish
  /// Minimal 1 daqiqa qaytaradi (agar sessiya boshlangan bo'lsa)
  int endSession(String type) {
    final start = _sessions.remove(type);
    if (start == null) return 0;
    
    final duration = DateTime.now().difference(start);
    // Minimal 1 daqiqa — qisqa sessiyalar ham hisobga olinsin
    return duration.inMinutes < 1 ? 1 : duration.inMinutes;
  }

  /// Joriy sessiya davomiyligini sekundlarda qaytarish
  int currentDurationSeconds(String type) {
    final start = _sessions[type];
    if (start == null) return 0;
    return DateTime.now().difference(start).inSeconds;
  }

  /// Joriy sessiya davomiyligini daqiqalarda qaytarish
  int currentDurationMinutes(String type) {
    final start = _sessions[type];
    if (start == null) return 0;
    return DateTime.now().difference(start).inMinutes;
  }

  /// Sessiya faolmi
  bool isActive(String type) => _sessions.containsKey(type);

  /// Har qanday sessiya faolmi
  bool get hasActiveSessions => _sessions.isNotEmpty;
}
