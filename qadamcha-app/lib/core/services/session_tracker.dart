import 'dart:async';
import 'local_monitoring_service.dart';

/// SessionTracker — Bola menusida vaqt tracking uchun service
/// 
/// Stack-based: har bir sahifa alohida sessiya ochadi, alohida tugatadi.
/// content, games, stories — hammasi bir vaqtda kuzatiladi.
/// LocalMonitoringService bilan integratsiya — local + backend saqlash.
/// 
/// ⚠️ child_home sessiyasi faqat tracking — addMinutes/counter chaqirMAYDI
/// (double counting oldini olish uchun)
class SessionTracker {
  SessionTracker._internal();
  static final SessionTracker instance = SessionTracker._internal();

  /// Har bir sessiya turi uchun alohida start vaqt
  final Map<String, DateTime> _sessions = {};
  
  /// Real-time vaqt yangilash uchun timer (har 10 soniyada)
  Timer? _realTimeTimer;

  /// Sessiya boshlash (oldingi sessiyani o'chirmaydi)
  void startSession(String type) {
    _sessions[type] = DateTime.now();
    _startRealTimeUpdates();
  }

  /// Sessiya tugatish va davomiylikni daqiqalarda qaytarish
  /// Minimal 1 daqiqa qaytaradi (agar sessiya boshlangan bo'lsa)
  int endSession(String type) {
    final start = _sessions.remove(type);
    if (start == null) return 0;
    
    final duration = DateTime.now().difference(start);
    // Minimal 1 daqiqa — qisqa sessiyalar ham hisobga olinsin
    final minutes = duration.inMinutes < 1 ? 1 : duration.inMinutes;
    
    // ⚠️ child_home — faqat tracker, addMinutes/counter chaqirMASLIK!
    // content/games/stories sessiyalari alohida hisoblaydi,
    // child_home ham hisoblasa double counting bo'ladi.
    if (type == 'child_home') {
      if (_sessions.isEmpty) {
        _stopRealTimeUpdates();
      }
      return minutes;
    }
    
    // Sessiya tugaganda local monitoring'ga yozish
    final monitoring = LocalMonitoringService.instance;
    monitoring.addMinutes(minutes);
    
    // Activity type ga qarab qo'shimcha counter'larni yangilash
    String activityType;
    String contentTitle;
    if (type == 'content') {
      monitoring.addVideoWatched();
      activityType = 'video_watch';
      contentTitle = 'Multfilm ko\'rish';
    } else if (type == 'games') {
      monitoring.addGamePlayed();
      activityType = 'game_play';
      contentTitle = 'O\'yin o\'ynash';
    } else if (type == 'stories') {
      monitoring.addStoryRead();
      activityType = 'story_read';
      contentTitle = 'Ertak o\'qish';
    } else {
      activityType = 'app_usage';
      contentTitle = 'Ilova foydalanish';
    }
    
    // Activity logga yozish (local + backend — addActivityLog ichida)
    // Bu metod local'ga ham, backend'ga ham yozadi
    monitoring.addActivityLog(
      activityType: activityType,
      contentTitle: contentTitle,
      durationMinutes: minutes,
    );

    // Sync ham chaqirish — usage counters ni backend ga
    monitoring.syncToBackend();
    
    // Agar boshqa aktiv sessiya yo'q bo'lsa, timer'ni to'xtatish
    if (_sessions.isEmpty) {
      _stopRealTimeUpdates();
    }
    
    return minutes;
  }

  /// Real-time vaqt yangilash timer'ni boshlash
  void _startRealTimeUpdates() {
    if (_realTimeTimer != null) return; // Allaqachon ishlayapti
    _realTimeTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      // Har 10 soniyada local monitoring'ga joriy vaqtni saqlash
      // Bu monitoring page'da real-time ko'rinishi uchun
      LocalMonitoringService.instance.saveToLocal();
    });
  }

  /// Real-time timer'ni to'xtatish
  void _stopRealTimeUpdates() {
    _realTimeTimer?.cancel();
    _realTimeTimer = null;
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
