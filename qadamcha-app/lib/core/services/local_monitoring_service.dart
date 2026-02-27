import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import '../network/api_client.dart';

/// LocalMonitoringService — Monitoring ma'lumotlarini local + backend saqlash
/// 
/// - Vaqt SONIYALARDA hisoblanadi (ichki), UI da daqiqaga o'tkaziladi
/// - Har 10 soniyada SharedPreferences ga auto-save
/// - Bola menuga kirganda backend→local sync, chiqqanda local→backend sync
/// - Activity log, weekly stats, last watched, subscription ham saqlanadi
/// - BLoC yoki UI callback'larga bog'liq EMAS
class LocalMonitoringService {
  LocalMonitoringService._internal();
  static final LocalMonitoringService instance = LocalMonitoringService._internal();

  SharedPreferences? _prefs;
  Timer? _autoSaveTimer;
  Timer? _syncTimer;
  Timer? _secondTimer; // Har soniyada counter oshiruvchi timer

  // In-memory counters (tez ishlash uchun)
  int _secondsUsed = 0; // Bugungi umumiy SONIYALAR
  int _videosWatched = 0;
  int _gamesPlayed = 0;
  int _storiesRead = 0;
  String? _childId;
  
  // Dirty flag — faqat o'zgarganda saqlash
  bool _isDirty = false;
  
  // Activity logs (local)
  List<Map<String, dynamic>> _activityLogs = [];
  
  // Weekly stats (local) — daqiqalarda (backend bilan mos)
  List<int> _weeklyMinutes = [0, 0, 0, 0, 0, 0, 0];
  
  // Prefix for SharedPreferences keys
  static const _keyPrefix = 'monitoring_';
  static const _keySeconds = '${_keyPrefix}secondsUsed';
  static const _keyVideos = '${_keyPrefix}videosWatched';
  static const _keyGames = '${_keyPrefix}gamesPlayed';
  static const _keyStories = '${_keyPrefix}storiesRead';
  static const _keyChildId = '${_keyPrefix}childId';
  static const _keyDate = '${_keyPrefix}date';
  static const _keyActivityLogs = '${_keyPrefix}activityLogs';
  static const _keyWeeklyMinutes = '${_keyPrefix}weeklyMinutes';
  static const _keyLastWatched = '${_keyPrefix}lastWatched';
  static const _keySubscription = '${_keyPrefix}subscription';
  static const _keyWeekNumber = '${_keyPrefix}weekNumber';

  /// O'zbekiston vaqti (UTC+5) — barcha sana hisob-kitoblari shu bilan
  static DateTime get _nowUzbekistan => DateTime.now().toUtc().add(const Duration(hours: 5));
  static String get _todayUzbekistan => _nowUzbekistan.toIso8601String().split('T')[0];
  /// ISO hafta raqami (yil + hafta)
  static String get _currentWeekNumber {
    final now = _nowUzbekistan;
    final firstDayOfYear = DateTime(now.year, 1, 1);
    final weekNumber = ((now.difference(firstDayOfYear).inDays + firstDayOfYear.weekday) / 7).ceil();
    return '${now.year}-W$weekNumber';
  }

  /// Service'ni boshlash (app startup da chaqiriladi)
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFromLocal();
    _startAutoSave();
  }

  /// Local'dan ma'lumotlarni yuklash
  void _loadFromLocal() {
    if (_prefs == null) return;
    
    // Haftalik reset tekshirish — yangi hafta boshida barcha kunlar 0 ga
    _checkWeeklyReset();
    
    // Bugungi sana tekshirish — agar kechagi bo'lsa, reset
    _checkDailyReset();
    
    _childId = _prefs!.getString(_keyChildId);
    _loadActivityLogs();
  }

  /// Kunlik reset tekshirish — yangi kunda barcha counterlar 0 ga
  void _checkDailyReset() {
    if (_prefs == null) return;
    final savedDate = _prefs!.getString(_keyDate);
    final today = _todayUzbekistan;
    
    if (savedDate != today) {
      if (kDebugMode) print('🔄 [LocalMonitoring] Yangi kun: $savedDate → $today — reset');
      // Yangi kun — kunlik counters'ni reset
      _secondsUsed = 0;
      _videosWatched = 0;
      _gamesPlayed = 0;
      _storiesRead = 0;
      _activityLogs = []; // Kunlik loglarni ham tozalash
      _saveActivityLogs();
      
      // Haftalik stats'da bugungi kunni reset
      _loadWeeklyMinutes();
      final todayIndex = _nowUzbekistan.weekday - 1;
      if (todayIndex >= 0 && todayIndex < 7) {
        _weeklyMinutes[todayIndex] = 0;
      }
      _saveWeeklyMinutes();
      
      saveToLocal();
      _prefs!.setString(_keyDate, today);
    } else {
      _secondsUsed = _prefs!.getInt(_keySeconds) ?? 0;
      _videosWatched = _prefs!.getInt(_keyVideos) ?? 0;
      _gamesPlayed = _prefs!.getInt(_keyGames) ?? 0;
      _storiesRead = _prefs!.getInt(_keyStories) ?? 0;
      _loadWeeklyMinutes();
    }
  }

  /// Haftalik reset — yangi hafta boshida barcha kunlar 0 ga qaytadi
  void _checkWeeklyReset() {
    if (_prefs == null) return;
    final savedWeek = _prefs!.getString(_keyWeekNumber);
    final currentWeek = _currentWeekNumber;
    
    if (savedWeek != null && savedWeek != currentWeek) {
      if (kDebugMode) print('🔄 [LocalMonitoring] Yangi hafta: $savedWeek → $currentWeek — to\'liq reset');
      _weeklyMinutes = [0, 0, 0, 0, 0, 0, 0];
      _saveWeeklyMinutes();
    }
    _prefs!.setString(_keyWeekNumber, currentWeek);
  }

  /// Auto-save timer boshlash (har 10 soniyada, faqat dirty bo'lganda)
  /// Har auto-save da kun chegarasini ham tekshiradi
  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      // Kun chegarasini tekshirish (yarim tunda reset bo'lishi uchun)
      _checkWeeklyReset();
      _checkDailyReset();
      
      if (_isDirty) {
        saveToLocal();
        _isDirty = false;
      }
    });
  }

  /// Auto-save timer'ni to'xtatish (bola menusi yopilganda)
  void pauseAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    if (_isDirty) {
      saveToLocal();
      _isDirty = false;
    }
  }

  /// Auto-save timer'ni qayta boshlash (bola menusiga kirganda)
  void resumeAutoSave() {
    if (_autoSaveTimer == null) {
      _startAutoSave();
    }
  }

  // ─── Soniya Timer (Global child_home uchun) ────────────────────────

  /// Har soniyada counter oshiruvchi timerni boshlash
  void startSecondTimer() {
    _secondTimer?.cancel();
    _secondTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _secondsUsed++;
      _isDirty = true;
    });
    if (kDebugMode) print('⏱️ [LocalMonitoring] Soniya timer boshlandi');
  }

  /// Soniya timerni to'xtatish
  void stopSecondTimer() {
    _secondTimer?.cancel();
    _secondTimer = null;
    saveToLocal(); // Oxirgi holatni saqlash
    if (kDebugMode) print('⏹️ [LocalMonitoring] Soniya timer to\'xtatildi (total: ${_secondsUsed}s = ${_secondsUsed ~/ 60}m)');
  }

  /// Soniya timer ishlayaptimi
  bool get isSecondTimerActive => _secondTimer != null;

  /// Local'ga saqlash (public — SessionTracker ham chaqiradi)
  void saveToLocal() {
    if (_prefs == null) return;
    _prefs!.setInt(_keySeconds, _secondsUsed);
    _prefs!.setInt(_keyVideos, _videosWatched);
    _prefs!.setInt(_keyGames, _gamesPlayed);
    _prefs!.setInt(_keyStories, _storiesRead);
    if (_childId != null) {
      _prefs!.setString(_keyChildId, _childId!);
    }
    _prefs!.setString(_keyDate, _todayUzbekistan);
    _prefs!.setString(_keyWeekNumber, _currentWeekNumber);
    
    // Haftalik stats'da bugungi kunni yangilash (daqiqalarda)
    final todayIndex = _nowUzbekistan.weekday - 1;
    if (todayIndex >= 0 && todayIndex < 7) {
      _weeklyMinutes[todayIndex] = _secondsUsed ~/ 60;
      _saveWeeklyMinutes();
    }
  }

  /// Backend sync timer — endi kerak emas, batchUpdate har sessiya oxirida sync qiladi
  void startSyncTimer() {
    // NO-OP: backward compatibility
  }

  /// Backend'ga to'g'ridan-to'g'ri sync qilish (Dio orqali)
  /// Soniyalarni daqiqaga o'tkazib yuboradi
  Future<void> syncToBackend() async {
    if (_childId == null || _childId!.isEmpty) {
      if (kDebugMode) print('⚠️ [LocalMonitoring] syncToBackend: childId null — sync qilinmadi');
      return;
    }

    try {
      final apiClient = GetIt.instance<ApiClient>();
      final minutes = _secondsUsed ~/ 60;
      if (kDebugMode) print('📤 [LocalMonitoring] syncToBackend: childId=$_childId sec=$_secondsUsed (${minutes}m), vid=$_videosWatched, game=$_gamesPlayed, story=$_storiesRead');
      
      final response = await apiClient.dio.post('/children/$_childId/sync-usage', data: {
        'minutesUsed': minutes,
        'videosWatched': _videosWatched,
        'gamesPlayed': _gamesPlayed,
        'storiesRead': _storiesRead,
      });
      
      if (kDebugMode) print('✅ [LocalMonitoring] syncToBackend: ${response.statusCode} ${response.data}');
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ [LocalMonitoring] syncToBackend DioException:');
        print('   statusCode: ${e.response?.statusCode}');
        print('   response: ${e.response?.data}');
        print('   message: ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ [LocalMonitoring] syncToBackend xato: $e');
    }
  }

  /// Activity ni backend'ga to'g'ridan-to'g'ri yozish (Dio orqali)
  /// MongoDB `activities` collection ga yozadi
  Future<void> recordActivityToBackend({
    required String activityType,
    required int durationMinutes,
    String? contentTitle,
    String? contentId,
  }) async {
    if (_childId == null || _childId!.isEmpty) {
      if (kDebugMode) print('⚠️ [LocalMonitoring] recordActivity: childId null — yozilmadi');
      return;
    }

    try {
      final apiClient = GetIt.instance<ApiClient>();
      if (kDebugMode) print('📝 [LocalMonitoring] recordActivity: childId=$_childId type=$activityType dur=$durationMinutes title=$contentTitle');
      
      final response = await apiClient.dio.post('/children/$_childId/activity', data: {
        'activityType': activityType,
        'durationMinutes': durationMinutes,
        if (contentTitle != null) 'contentTitle': contentTitle,
        if (contentId != null && contentId.isNotEmpty) 'contentId': contentId,
      });
      
      if (kDebugMode) print('✅ [LocalMonitoring] recordActivity: ${response.statusCode} ${response.data}');
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ [LocalMonitoring] recordActivity DioException:');
        print('   statusCode: ${e.response?.statusCode}');
        print('   response: ${e.response?.data}');
        print('   message: ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ [LocalMonitoring] recordActivity xato: $e');
    }
  }

  // ─── Activity Logs ──────────────────────────────────────────────────

  void _loadActivityLogs() {
    final json = _prefs?.getString(_keyActivityLogs);
    if (json != null) {
      try {
        final list = jsonDecode(json) as List;
        _activityLogs = list.cast<Map<String, dynamic>>();
      } catch (_) {
        _activityLogs = [];
      }
    }
  }

  void _saveActivityLogs() {
    if (_prefs == null) return;
    // Oxirgi 20 ta logni saqlash (ko'p bo'lmasin)
    final toSave = _activityLogs.take(20).toList();
    _prefs!.setString(_keyActivityLogs, jsonEncode(toSave));
  }

  /// Yangi faoliyat qo'shish (faqat local — backend batchUpdate da)
  void _addActivityLogLocal({
    required String activityType,
    required String contentTitle,
    required int durationMinutes,
  }) {
    _activityLogs.insert(0, {
      'activityType': activityType,
      'contentTitle': contentTitle,
      'durationMinutes': durationMinutes,
      'startedAt': DateTime.now().toIso8601String(),
    });
    if (_activityLogs.length > 20) {
      _activityLogs = _activityLogs.sublist(0, 20);
    }
    _saveActivityLogs();
  }

  /// Yangi faoliyat qo'shish (local + backend) — backward compatibility
  void addActivityLog({
    required String activityType,
    required String contentTitle,
    required int durationMinutes,
  }) {
    _addActivityLogLocal(
      activityType: activityType,
      contentTitle: contentTitle,
      durationMinutes: durationMinutes,
    );
    // Backend'ga ham yozish (asinxron — UI blocklash yo'q)
    recordActivityToBackend(
      activityType: activityType,
      durationMinutes: durationMinutes,
      contentTitle: contentTitle,
    );
  }

  /// Batch yangilash — sessiya tugaganda faqat counter'larni oshirish
  /// Vaqt global timer tomonidan hisoblanadi — bu yerda vaqt QO'SHILMAYDI
  void batchUpdate({
    required int seconds,
    required String activityType,
    required String contentTitle,
    required int durationMinutes,
  }) {
    // 1. Faqat activity turi bo'yicha counter oshiriladi
    // Vaqt global timer (_secondTimer) tomonidan allaqachon hisoblanmoqda
    if (activityType == 'video_watch') {
      _videosWatched++;
    } else if (activityType == 'game_play') {
      _gamesPlayed++;
    } else if (activityType == 'story_read') {
      _storiesRead++;
    }

    // 2. Activity log qo'shish (faqat local — UI uchun)
    _addActivityLogLocal(
      activityType: activityType,
      contentTitle: contentTitle,
      durationMinutes: durationMinutes,
    );

    // 3. Faqat 1 marta saveToLocal
    saveToLocal();
    _isDirty = false;

    // ✅ Activity ni backend ga yozish (faqat tur va title)
    // Vaqt syncToBackend orqali boshqariladi (child_home chiqqanda)
    // Bu yerda faqat Activity collection ga log yoziladi
    recordActivityToBackend(
      activityType: activityType,
      durationMinutes: durationMinutes > 0 ? durationMinutes : 1,
      contentTitle: contentTitle,
    );
  }

  /// Local activity loglarni olish
  List<Map<String, dynamic>> get activityLogs => _activityLogs;

  // ─── Weekly Stats ───────────────────────────────────────────────────

  void _loadWeeklyMinutes() {
    final json = _prefs?.getString(_keyWeeklyMinutes);
    if (json != null) {
      try {
        final list = jsonDecode(json) as List;
        _weeklyMinutes = list.cast<int>();
        if (_weeklyMinutes.length != 7) {
          _weeklyMinutes = [0, 0, 0, 0, 0, 0, 0];
        }
      } catch (_) {
        _weeklyMinutes = [0, 0, 0, 0, 0, 0, 0];
      }
    }
  }

  void _saveWeeklyMinutes() {
    if (_prefs == null) return;
    _prefs!.setString(_keyWeeklyMinutes, jsonEncode(_weeklyMinutes));
  }

  /// Haftalik daqiqalar (Du=0 ... Ya=6)
  List<int> get weeklyMinutes => List.unmodifiable(_weeklyMinutes);

  /// Haftalik jami daqiqalar
  int get weeklyTotalMinutes => _weeklyMinutes.fold(0, (a, b) => a + b);

  // ─── Last Watched (ro'yxat) ────────────────────────────────────────

  /// Oxirgi ko'rilgan kontentni ro'yxatga qo'shish (dublikatlarni olib tashlash)
  void saveLastWatched(Map<String, dynamic> contentJson) {
    if (_prefs == null) return;
    final list = getLastWatchedList();
    // Dublikatni olib tashlash (id bo'yicha)
    list.removeWhere((item) => item['id'] == contentJson['id']);
    // Boshiga qo'shish
    list.insert(0, contentJson);
    // Faqat oxirgi 10 tasini saqlash
    final toSave = list.take(10).toList();
    _prefs!.setString(_keyLastWatched, jsonEncode(toSave));
  }

  /// Oxirgi ko'rilgan kontentni olish (bitta — backward compatibility)
  Map<String, dynamic>? getLastWatched() {
    final list = getLastWatchedList();
    return list.isNotEmpty ? list.first : null;
  }

  /// Oxirgi ko'rilgan kontentlar ro'yxatini olish
  List<Map<String, dynamic>> getLastWatchedList() {
    final json = _prefs?.getString(_keyLastWatched);
    if (json == null) return [];
    try {
      final decoded = jsonDecode(json);
      // Eski format (bitta Map) ni ro'yxatga o'zgartirish
      if (decoded is Map<String, dynamic>) {
        return [decoded];
      }
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ─── Subscription Persistence ──────────────────────────────────────

  /// Obuna holatini local saqlash
  void saveSubscription(Map<String, dynamic> subscriptionJson) {
    if (_prefs == null) return;
    _prefs!.setString(_keySubscription, jsonEncode(subscriptionJson));
  }

  /// Obuna holatini olish
  Map<String, dynamic>? getSubscription() {
    final json = _prefs?.getString(_keySubscription);
    if (json == null) return null;
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Obuna holatini tozalash
  void clearSubscription() {
    _prefs?.remove(_keySubscription);
  }

  // ─── Backend dan yuklash (qayta o'rnatishdan keyin) ─────────────────

  /// Backend'dan kelgan todayUsage ni lokal counterlar ga sync qilish
  /// Backend daqiqada yuboradi — biz soniyaga o'tkazib saqlaymiz
  /// Re-login qilganda backend qiymatlari to'g'ridan-to'g'ri yoziladi
  void loadFromBackend({
    required int minutesUsed,
    required int videosWatched,
    required int gamesPlayed,
    required int storiesRead,
  }) {
    if (kDebugMode) {
      print('🔄 [LocalMonitoring] loadFromBackend chaqirildi:');
      print('   Backend: min=$minutesUsed, vid=$videosWatched, game=$gamesPlayed, story=$storiesRead');
      print('   Local:   sec=$_secondsUsed (${_secondsUsed ~/ 60}m), vid=$_videosWatched, game=$_gamesPlayed, story=$_storiesRead');
    }
    
    bool changed = false;
    // Backend daqiqani soniyaga o'tkazish
    final backendSeconds = minutesUsed * 60;
    if (backendSeconds > _secondsUsed) {
      _secondsUsed = backendSeconds;
      changed = true;
    }
    if (videosWatched > _videosWatched) {
      _videosWatched = videosWatched;
      changed = true;
    }
    if (gamesPlayed > _gamesPlayed) {
      _gamesPlayed = gamesPlayed;
      changed = true;
    }
    if (storiesRead > _storiesRead) {
      _storiesRead = storiesRead;
      changed = true;
    }
    
    if (changed) {
      if (kDebugMode) print('   ✅ Yangilandi → sec=$_secondsUsed (${_secondsUsed ~/ 60}m), vid=$_videosWatched, game=$_gamesPlayed, story=$_storiesRead');
      saveToLocal();
    } else {
      if (kDebugMode) print('   ℹ️ O\'zgarmadi (local >= backend)');
    }
  }

  /// Backend'dan kelgan haftalik statistikani lokal ga sync qilish
  void loadWeeklyFromBackend(List<int> backendWeekly) {
    if (backendWeekly.length != 7) return;
    bool changed = false;
    for (int i = 0; i < 7; i++) {
      if (backendWeekly[i] > _weeklyMinutes[i]) {
        _weeklyMinutes[i] = backendWeekly[i];
        changed = true;
      }
    }
    if (changed) {
      _saveWeeklyMinutes();
    }
  }

  // ─── Data setters ───────────────────────────────────────────────────

  /// Child ID ni olish (getter)
  String? get childId => _childId;

  /// Child ID o'rnatish
  void setChildId(String? id) {
    _childId = id;
    if (_prefs != null && id != null) {
      _prefs!.setString(_keyChildId, id);
    }
    if (kDebugMode) print('🆔 [LocalMonitoring] setChildId: $_childId');
  }

  /// Soniya qo'shish — saveToLocal chaqirMAYDI, dirty flag qo'yadi
  void addSeconds(int seconds) {
    _secondsUsed += seconds;
    _isDirty = true;
  }

  /// Video ko'rildi — saveToLocal chaqirMAYDI, dirty flag qo'yadi
  void addVideoWatched() {
    _videosWatched++;
    _isDirty = true;
  }

  /// O'yin o'ynaldi — saveToLocal chaqirMAYDI, dirty flag qo'yadi
  void addGamePlayed() {
    _gamesPlayed++;
    _isDirty = true;
  }

  /// Ertak o'qildi — saveToLocal chaqirMAYDI, dirty flag qo'yadi
  void addStoryRead() {
    _storiesRead++;
    _isDirty = true;
  }

  // ─── Data getters ───────────────────────────────────────────────────

  /// Umumiy soniyalar (ichki)
  int get secondsUsed => _secondsUsed;

  /// Umumiy daqiqalar (UI uchun — soniyani daqiqaga o'tkazadi)
  int get minutesUsed => _secondsUsed ~/ 60;

  int get videosWatched => _videosWatched;
  int get gamesPlayed => _gamesPlayed;
  int get storiesRead => _storiesRead;

  /// Barcha ma'lumotlarni Map sifatida olish
  Map<String, int> get allStats => {
    'secondsUsed': _secondsUsed,
    'minutesUsed': _secondsUsed ~/ 60,
    'videosWatched': _videosWatched,
    'gamesPlayed': _gamesPlayed,
    'storiesRead': _storiesRead,
  };

  /// Barcha ma'lumotlarni saqlash (menu tark etganda)
  void syncAllToBackend() {
    saveToLocal();
  }

  // ─── Lifecycle ──────────────────────────────────────────────────────

  /// Timerlarni to'xtatish (app background ga o'tganda)
  void dispose() {
    saveToLocal(); // Oxirgi marta local saqlash
    _autoSaveTimer?.cancel();
    _syncTimer?.cancel();
    _secondTimer?.cancel();
  }

  /// Kunlik reset (yangi kun boshlanganda)
  void resetDaily() {
    _secondsUsed = 0;
    _videosWatched = 0;
    _gamesPlayed = 0;
    _storiesRead = 0;
    saveToLocal();
  }
}
