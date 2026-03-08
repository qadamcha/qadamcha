import 'package:shared_preferences/shared_preferences.dart';

class JigsawStorageService {
  static const _prefix = 'puzzle_';

  static Future<void> saveLevelCompleted(
      String levelId, int stars, int timeSeconds, int moves) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_prefix}completed_$levelId', true);
    final oldStars = prefs.getInt('${_prefix}stars_$levelId') ?? 0;
    if (stars > oldStars) {
      await prefs.setInt('${_prefix}stars_$levelId', stars);
    }
    await prefs.setInt('${_prefix}time_$levelId', timeSeconds);
    await prefs.setInt('${_prefix}moves_$levelId', moves);
  }

  static Future<bool> isLevelCompleted(String levelId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('${_prefix}completed_$levelId') ?? false;
  }

  static Future<int> getLevelStars(String levelId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('${_prefix}stars_$levelId') ?? 0;
  }

  static Future<int> getTotalStars() async {
    final prefs = await SharedPreferences.getInstance();
    int total = 0;
    for (final key in prefs.getKeys()) {
      if (key.startsWith('${_prefix}stars_')) {
        total += prefs.getInt(key) ?? 0;
      }
    }
    return total;
  }

  static Future<int> getTotalCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    int count = 0;
    for (final key in prefs.getKeys()) {
      if (key.startsWith('${_prefix}completed_') &&
          (prefs.getBool(key) ?? false)) {
        count++;
      }
    }
    return count;
  }
}
