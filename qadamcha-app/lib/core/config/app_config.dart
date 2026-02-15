import 'dart:io' show Platform;

/// Dinamik konfiguratsiya - build vaqtida --dart-define orqali beriladi.
///
/// Ishlatish (production — Railway):
///   flutter run --dart-define=ENV=production
///   flutter build apk --release --dart-define=ENV=production
///
/// Ishlatish (development — local backend):
///   flutter run --dart-define=ENV=development
///   flutter run --dart-define=ENV=development --dart-define=API_HOST=192.168.0.105
///
/// Default: production (Railway URL).
class AppConfig {
  AppConfig._();

  // --dart-define=ENV=production
  static const String _env = String.fromEnvironment(
    'ENV',
    defaultValue: 'production',
  );

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

  /// Production rejimmi?
  static bool get isProduction => _env == 'production';

  /// Backend host — production da Railway, dev da local.
  static String get apiHost {
    if (_apiHost.isNotEmpty) return _apiHost;
    if (isProduction) return 'qadamcha-production.up.railway.app';
    return Platform.isAndroid ? '10.0.2.2' : 'localhost';
  }

  /// To'liq API base URL
  static String get baseUrl {
    if (isProduction) return 'https://$apiHost/api/v1';
    return 'http://$apiHost:$_apiPort/api/v1';
  }

  /// Content Uploader URL (ertak, multfilm yuklash uchun)
  static String get contentUploaderUrl {
    if (isProduction) return 'https://qadamcha-content-uploader.up.railway.app';
    // Development da Android emulator 10.0.2.2, iOS localhost
    return 'http://${Platform.isAndroid ? '10.0.2.2' : 'localhost'}:4000';
  }
}
