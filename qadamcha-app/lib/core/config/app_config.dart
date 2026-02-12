import 'dart:io' show Platform;

/// Dinamik konfiguratsiya - build vaqtida --dart-define orqali beriladi.
///
/// Ishlatish:
///   flutter run --dart-define=API_HOST=192.168.0.105
///   flutter run --dart-define=API_HOST=192.168.0.105 --dart-define=API_PORT=3001
///
/// Default: Android emulator uchun 10.0.2.2, iOS simulator uchun localhost.
class AppConfig {
  AppConfig._();

  // --dart-define=API_HOST=x.x.x.x
  static const String _apiHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: '',
  );

  // --dart-define=API_PORT=3000
  static const String _apiPort = String.fromEnvironment(
    'API_PORT',
    defaultValue: '3000',
  );

  /// Backend host — dart-define bilan berilmasa platforma bo'yicha default.
  static String get apiHost {
    if (_apiHost.isNotEmpty) return _apiHost;
    // Android emulator 10.0.2.2 orqali host mashinaga ulanadi
    // iOS simulator localhost orqali ulanadi
    return Platform.isAndroid ? '10.0.2.2' : 'localhost';
  }

  /// To'liq API base URL
  static String get baseUrl => 'http://$apiHost:$_apiPort/api/v1';
}
