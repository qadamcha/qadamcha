/// SessionTracker — Bola menusida vaqt tracking uchun singleton service
/// 
/// Foydalanish:
/// - ChildHomePage: SessionTracker.instance.startSession('child_home')
/// - ContentPage:   SessionTracker.instance.startSession('content')
/// - GamesPage:     SessionTracker.instance.startSession('games')
class SessionTracker {
  SessionTracker._internal();
  static final SessionTracker instance = SessionTracker._internal();

  DateTime? _sessionStart;
  String? _currentSessionType;

  /// Sessiya boshlash
  void startSession(String type) {
    _currentSessionType = type;
    _sessionStart = DateTime.now();
  }

  /// Sessiya tugatish va davomiylikni daqiqalarda qaytarish
  /// Minimal 1 daqiqa qaytaradi (agar sessiya boshlangan bo'lsa)
  int endSession() {
    if (_sessionStart == null) return 0;
    
    final duration = DateTime.now().difference(_sessionStart!);
    // Minimal 1 daqiqa — qisqa sessiyalar ham hisobga olinsin
    final minutes = duration.inMinutes < 1 ? 1 : duration.inMinutes;
    
    _sessionStart = null;
    _currentSessionType = null;
    
    return minutes;
  }

  /// Joriy sessiya davomiyligini sekundlarda qaytarish
  int get currentDurationSeconds {
    if (_sessionStart == null) return 0;
    return DateTime.now().difference(_sessionStart!).inSeconds;
  }

  /// Joriy sessiya davomiyligini daqiqalarda qaytarish
  int get currentDurationMinutes {
    if (_sessionStart == null) return 0;
    return DateTime.now().difference(_sessionStart!).inMinutes;
  }

  /// Joriy sessiya turi
  String? get currentType => _currentSessionType;

  /// Sessiya faolmi
  bool get isActive => _sessionStart != null;
}
