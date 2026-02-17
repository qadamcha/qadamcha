import 'dart:async';
import 'local_monitoring_service.dart';

/// SessionTracker — Bola menusida vaqt tracking uchun service
/// 
/// Stack-based: har bir sahifa alohida sessiya ochadi, alohida tugatadi.
/// child_home, content, games — hammasi bir vaqtda kuzatiladi.
/// LocalMonitoringService bilan integratsiya — real-time vaqt yangilanishi.
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
    
    // Sessiya tugaganda local monitoring'ga yozish
    final monitoring = LocalMonitoringService.instance;
    monitoring.addMinutes(minutes);
    
    // Activity type ga qarab qo'shimcha counter'larni yangilash
    if (type == 'content') {
      monitoring.addVideoWatched();
    } else if (type == 'games') {
      monitoring.addGamePlayed();
    }
    
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
