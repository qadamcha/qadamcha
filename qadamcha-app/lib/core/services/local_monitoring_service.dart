import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import '../network/api_client.dart';

/// LocalMonitoringService — Monitoring ma'lumotlarini local + backend saqlash
/// 
/// - Har 10 soniyada SharedPreferences ga auto-save
/// - Har 5 daqiqada backend'ga to'g'ridan-to'g'ri sync (ApiClient orqali)
/// - Activity log, weekly stats, last watched, subscription ham saqlanadi
/// - BLoC yoki UI callback'larga bog'liq EMAS
class LocalMonitoringService {
  LocalMonitoringService._internal();
  static final LocalMonitoringService instance = LocalMonitoringService._internal();

  SharedPreferences? _prefs;
  Timer? _autoSaveTimer;
  Timer? _syncTimer;

  // In-memory counters (tez ishlash uchun)
  int _minutesUsed = 0;
  int _videosWatched = 0;
  int _gamesPlayed = 0;
  int _storiesRead = 0;
  String? _childId;
  
  // Dirty flag — faqat o'zgarganda saqlash
  bool _isDirty = false;
  
  // Activity logs (local)
  List<Map<String, dynamic>> _activityLogs = [];
  
  // Weekly stats (local)
  List<int> _weeklyMinutes = [0, 0, 0, 0, 0, 0, 0];
  
  // Prefix for SharedPreferences keys
  static const _keyPrefix = 'monitoring_';
  static const _keyMinutes = '${_keyPrefix}minutesUsed';
  static const _keyVideos = '${_keyPrefix}videosWatched';
  static const _keyGames = '${_keyPrefix}gamesPlayed';
  static const _keyStories = '${_keyPrefix}storiesRead';
  static const _keyChildId = '${_keyPrefix}childId';
  static const _keyDate = '${_keyPrefix}date';
  static const _keyActivityLogs = '${_keyPrefix}activityLogs';
  static const _keyWeeklyMinutes = '${_keyPrefix}weeklyMinutes';
  static const _keyLastWatched = '${_keyPrefix}lastWatched';
  static const _keySubscription = '${_keyPrefix}subscription';

  /// Service'ni boshlash (app startup da chaqiriladi)
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFromLocal();
    _startAutoSave();
  }

  /// Local'dan ma'lumotlarni yuklash
  void _loadFromLocal() {
    if (_prefs == null) return;
    
    // Bugungi sana tekshirish — agar kechagi bo'lsa, reset
    final savedDate = _prefs!.getString(_keyDate);
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    if (savedDate != today) {
      // Yangi kun — kunlik counters'ni reset
      _minutesUsed = 0;
      _videosWatched = 0;
      _gamesPlayed = 0;
      _storiesRead = 0;
      
      // Haftalik stats'ni yangilash — bugungi kunni reset
      _loadWeeklyMinutes();
      final todayIndex = DateTime.now().weekday - 1;
      if (todayIndex >= 0 && todayIndex < 7) {
        _weeklyMinutes[todayIndex] = 0;
      }
      _saveWeeklyMinutes();
      
      saveToLocal();
      _prefs!.setString(_keyDate, today);
    } else {
      _minutesUsed = _prefs!.getInt(_keyMinutes) ?? 0;
      _videosWatched = _prefs!.getInt(_keyVideos) ?? 0;
      _gamesPlayed = _prefs!.getInt(_keyGames) ?? 0;
      _storiesRead = _prefs!.getInt(_keyStories) ?? 0;
      _loadWeeklyMinutes();
    }
    _childId = _prefs!.getString(_keyChildId);
    _loadActivityLogs();
  }

  /// Auto-save timer boshlash (har 10 soniyada, faqat dirty bo'lganda)
  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
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

  /// Local'ga saqlash (public — SessionTracker ham chaqiradi)
  void saveToLocal() {
    if (_prefs == null) return;
    _prefs!.setInt(_keyMinutes, _minutesUsed);
    _prefs!.setInt(_keyVideos, _videosWatched);
    _prefs!.setInt(_keyGames, _gamesPlayed);
    _prefs!.setInt(_keyStories, _storiesRead);
    if (_childId != null) {
      _prefs!.setString(_keyChildId, _childId!);
    }
    _prefs!.setString(_keyDate, DateTime.now().toIso8601String().split('T')[0]);
    
    // Haftalik stats'da bugungi kunni yangilash
    final todayIndex = DateTime.now().weekday - 1;
    if (todayIndex >= 0 && todayIndex < 7) {
      _weeklyMinutes[todayIndex] = _minutesUsed;
      _saveWeeklyMinutes();
    }
  }

  /// Backend sync timer — endi kerak emas, batchUpdate har sessiya oxirida sync qiladi
  /// Backward compatibility uchun saqlab qo'yilgan, lekin hech narsa qilmaydi
  void startSyncTimer() {
    // NO-OP: batchUpdate har sessiya oxirida recordActivityToBackend chaqiradi
    // Ushbu metod faqat eski koddan chaqirilganda xato bermasligi uchun qoldirilgan
  }

  /// Backend'ga to'g'ridan-to'g'ri sync qilish (Dio orqali)
  Future<void> syncToBackend() async {
    if (_childId == null || _childId!.isEmpty) {
      if (kDebugMode) print('⚠️ [LocalMonitoring] syncToBackend: childId null — sync qilinmadi');
      return;
    }

    try {
      final apiClient = GetIt.instance<ApiClient>();
      if (kDebugMode) print('📤 [LocalMonitoring] syncToBackend: childId=$_childId min=$_minutesUsed, vid=$_videosWatched, game=$_gamesPlayed, story=$_storiesRead');
      
      final response = await apiClient.dio.post('/children/$_childId/sync-usage', data: {
        'minutesUsed': _minutesUsed,
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

  /// Batch yangilash — sessiya tugaganda barcha counter'larni
  /// bir marta saqlash + bitta API call
  void batchUpdate({
    required int minutes,
    required String activityType,
    required String contentTitle,
    required int durationMinutes,
  }) {
    // 1. Counter'larni oshirish (saveToLocal chaqirMASLIK)
    _minutesUsed += minutes;
    if (activityType == 'video_watch') {
      _videosWatched++;
    } else if (activityType == 'game_play') {
      _gamesPlayed++;
    } else if (activityType == 'story_read') {
      _storiesRead++;
    }

    // 2. Activity log qo'shish (faqat local)
    _addActivityLogLocal(
      activityType: activityType,
      contentTitle: contentTitle,
      durationMinutes: durationMinutes,
    );

    // 3. Faqat 1 marta saveToLocal
    saveToLocal();
    _isDirty = false;

    // 4. Faqat 1 ta API call — recordActivity
    // (syncToBackend kerak emas — recordActivity backend'da Activity yozadi)
    recordActivityToBackend(
      activityType: activityType,
      durationMinutes: durationMinutes,
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
  /// Backend — asosiy haqiqat manbai (source of truth)
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
      print('   Local:   min=$_minutesUsed, vid=$_videosWatched, game=$_gamesPlayed, story=$_storiesRead');
    }
    
    bool changed = false;
    if (minutesUsed > _minutesUsed) {
      _minutesUsed = minutesUsed;
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
      if (kDebugMode) print('   ✅ Yangilandi → min=$_minutesUsed, vid=$_videosWatched, game=$_gamesPlayed, story=$_storiesRead');
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

  /// Vaqt qo'shish (daqiqalarda) — saveToLocal chaqirMAYDI, dirty flag qo'yadi
  void addMinutes(int minutes) {
    _minutesUsed += minutes;
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

  int get minutesUsed => _minutesUsed;
  int get videosWatched => _videosWatched;
  int get gamesPlayed => _gamesPlayed;
  int get storiesRead => _storiesRead;

  /// Barcha ma'lumotlarni Map sifatida olish
  Map<String, int> get allStats => {
    'minutesUsed': _minutesUsed,
    'videosWatched': _videosWatched,
    'gamesPlayed': _gamesPlayed,
    'storiesRead': _storiesRead,
  };

  /// Barcha ma'lumotlarni saqlash (menu tark etganda)
  void syncAllToBackend() {
    // ✅ OPTIMIZED: syncToBackend olib tashlandi
    // batchUpdate har sessiya tugaganda recordActivityToBackend chaqiradi
    saveToLocal();
  }

  // ─── Lifecycle ──────────────────────────────────────────────────────

  /// Timerlarni to'xtatish (app background ga o'tganda)
  void dispose() {
    // ✅ OPTIMIZED: syncToBackend olib tashlandi
    // pauseAutoSave dirty datani saqlaydi, batchUpdate allaqachon backend'ga yozgan
    saveToLocal(); // Oxirgi marta local saqlash
    _autoSaveTimer?.cancel();
    _syncTimer?.cancel();
  }

  /// Kunlik reset (yangi kun boshlanganda)
  void resetDaily() {
    _minutesUsed = 0;
    _videosWatched = 0;
    _gamesPlayed = 0;
    _storiesRead = 0;
    saveToLocal();
  }
}
