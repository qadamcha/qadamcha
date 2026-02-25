import 'dart:async';
import 'local_monitoring_service.dart';

/// SessionTracker — Bola menusida vaqt tracking uchun service
/// 
/// Stack-based: har bir sahifa alohida sessiya ochadi, alohida tugatadi.
/// content, games, stories — hammasi bir vaqtda kuzatiladi.
/// LocalMonitoringService bilan integratsiya — local + backend saqlash.
/// 
/// ⚠️ child_home sessiyasi — GLOBAL TIMER
/// Bola menuga kirganda soniya timer boshlanadi, chiqqanda to'xtaydi.
/// Alohida content/games/stories sessiyalari faqat activity counter oshiradi.
class SessionTracker {
  SessionTracker._internal();
  static final SessionTracker instance = SessionTracker._internal();

  /// Har bir sessiya turi uchun alohida start vaqt
  final Map<String, DateTime> _sessions = {};

  /// Sessiya boshlash (oldingi sessiyani o'chirmaydi)
  void startSession(String type) {
    _sessions[type] = DateTime.now();
    
    if (type == 'child_home') {
      // Global soniya timer boshlash
      LocalMonitoringService.instance.startSecondTimer();
      LocalMonitoringService.instance.resumeAutoSave();
    }
  }

  /// Sessiya tugatish va davomiylikni daqiqalarda qaytarish
  /// Minimal 1 daqiqa qaytaradi (agar sessiya boshlangan bo'lsa)
  int endSession(String type) {
    final start = _sessions.remove(type);
    if (start == null) return 0;
    
    final duration = DateTime.now().difference(start);
    // Minimal 1 daqiqa — qisqa sessiyalar ham hisobga olinsin
    final minutes = duration.inMinutes < 1 ? 1 : duration.inMinutes;
    
    // ⚠️ child_home — GLOBAL TIMER to'xtatish + sync
    if (type == 'child_home') {
      // Soniya timerni to'xtatish
      LocalMonitoringService.instance.stopSecondTimer();
      // Bola menusidan chiqqanda auto-save to'xtatish
      LocalMonitoringService.instance.pauseAutoSave();
      // Backend'ga sync qilish (chiqqanda)
      LocalMonitoringService.instance.syncToBackend();
      return minutes;
    }
    
    // Activity type aniqlash
    String activityType;
    String contentTitle;
    if (type == 'content') {
      activityType = 'video_watch';
      contentTitle = 'Multfilm ko\'rish';
    } else if (type == 'games') {
      activityType = 'game_play';
      contentTitle = 'O\'yin o\'ynash';
    } else if (type == 'stories') {
      activityType = 'story_read';
      contentTitle = 'Ertak o\'qish';
    } else {
      activityType = 'app_usage';
      contentTitle = 'Ilova foydalanish';
    }
    
    // ✅ batchUpdate — faqat activity counter oshiradi
    // (vaqt global timer tomonidan allaqachon hisoblanmoqda)
    LocalMonitoringService.instance.batchUpdate(
      seconds: duration.inSeconds,
      activityType: activityType,
      contentTitle: contentTitle,
      durationMinutes: minutes,
    );
    
    return minutes;
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
