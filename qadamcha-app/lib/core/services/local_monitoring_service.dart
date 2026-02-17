import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// LocalMonitoringService — Monitoring ma'lumotlarini local saqlash
/// 
/// - Har 10 soniyada SharedPreferences ga auto-save
/// - Monitoring page bu service'dan o'qiydi
/// - Har 5 daqiqada backend'ga sync qilinadi (ChildBloc orqali)
class LocalMonitoringService {
  LocalMonitoringService._internal();
  static final LocalMonitoringService instance = LocalMonitoringService._internal();

  SharedPreferences? _prefs;
  Timer? _autoSaveTimer;
  Timer? _syncTimer;
  
  // Callback for backend sync
  void Function(Map<String, int> data)? onSyncToBackend;

  // In-memory counters (tez ishlash uchun)
  int _minutesUsed = 0;
  int _videosWatched = 0;
  int _gamesPlayed = 0;
  int _storiesRead = 0;
  String? _childId;
  
  // Prefix for SharedPreferences keys
  static const _keyPrefix = 'monitoring_';
  static const _keyMinutes = '${_keyPrefix}minutesUsed';
  static const _keyVideos = '${_keyPrefix}videosWatched';
  static const _keyGames = '${_keyPrefix}gamesPlayed';
  static const _keyStories = '${_keyPrefix}storiesRead';
  static const _keyChildId = '${_keyPrefix}childId';
  static const _keyLastSync = '${_keyPrefix}lastSync';
  static const _keyDate = '${_keyPrefix}date';

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
      // Yangi kun — counters'ni reset
      _minutesUsed = 0;
      _videosWatched = 0;
      _gamesPlayed = 0;
      _storiesRead = 0;
      saveToLocal(); // Reset qiymatlarni saqlash
      _prefs!.setString(_keyDate, today);
    } else {
      _minutesUsed = _prefs!.getInt(_keyMinutes) ?? 0;
      _videosWatched = _prefs!.getInt(_keyVideos) ?? 0;
      _gamesPlayed = _prefs!.getInt(_keyGames) ?? 0;
      _storiesRead = _prefs!.getInt(_keyStories) ?? 0;
    }
    _childId = _prefs!.getString(_keyChildId);
  }

  /// Auto-save timer boshlash (har 10 soniyada)
  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      saveToLocal();
    });
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
  }

  /// Backend sync timer boshlash (har 5 daqiqada)
  void startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      syncToBackend();
    });
  }

  /// Backend'ga sync qilish
  void syncToBackend() {
    if (onSyncToBackend != null) {
      onSyncToBackend!({
        'minutesUsed': _minutesUsed,
        'videosWatched': _videosWatched,
        'gamesPlayed': _gamesPlayed,
        'storiesRead': _storiesRead,
      });
    }
  }

  // ─── Data setters ───────────────────────────────────────────────────

  /// Child ID o'rnatish
  void setChildId(String? id) {
    _childId = id;
    if (_prefs != null && id != null) {
      _prefs!.setString(_keyChildId, id);
    }
  }

  /// Vaqt qo'shish (daqiqalarda)
  void addMinutes(int minutes) {
    _minutesUsed += minutes;
    saveToLocal();
  }

  /// Video ko'rildi
  void addVideoWatched() {
    _videosWatched++;
    saveToLocal();
  }

  /// O'yin o'ynaldi
  void addGamePlayed() {
    _gamesPlayed++;
    saveToLocal();
  }

  /// Ertak o'qildi
  void addStoryRead() {
    _storiesRead++;
    saveToLocal();
  }

  // ─── Data getters ───────────────────────────────────────────────────

  int get minutesUsed => _minutesUsed;
  int get videosWatched => _videosWatched;
  int get gamesPlayed => _gamesPlayed;
  int get storiesRead => _storiesRead;
  String? get childId => _childId;

  /// Barcha ma'lumotlarni Map sifatida olish
  Map<String, int> get allStats => {
    'minutesUsed': _minutesUsed,
    'videosWatched': _videosWatched,
    'gamesPlayed': _gamesPlayed,
    'storiesRead': _storiesRead,
  };

  // ─── Lifecycle ──────────────────────────────────────────────────────

  /// Timerlarni to'xtatish (app background ga o'tganda)
  void dispose() {
    saveToLocal(); // Oxirgi marta saqlash
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
