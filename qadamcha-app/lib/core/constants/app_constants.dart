import 'package:qadamcha_app/core/config/app_config.dart';

// API Configuration
class ApiConstants {
  /// Dinamik API URL — `--dart-define=API_HOST=x.x.x.x` orqali o'zgartiriladi.
  /// Default: Android emulator → 10.0.2.2, iOS → localhost.
  static String get baseUrl => AppConfig.baseUrl;
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

// Storage Keys
class StorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String phoneNumber = 'phone_number';
  static const String deviceId = 'device_id';
  static const String isLoggedIn = 'is_logged_in';
  static const String selectedChild = 'selected_child';
  static const String appMode = 'app_mode'; // parent or child
  static const String onboardingDone = 'onboarding_done';
}

// App Constants
class AppConstants {
  static const String appName = 'Qadamcha';
  static const int otpLength = 6;
  static const int pinLength = 4;
  static const int maxDevices = 3;
  static const int maxChildren = 5;
  static const Duration otpResendDelay = Duration(seconds: 60);
}

// Time Limits (daqiqalarda)
class TimeLimits {
  static const int minDaily = 5;
  static const int maxDaily = 480; // 8 soat
  static const int defaultDaily = 60;
  static const int defaultWeekday = 60;
  static const int defaultWeekend = 120;
}

// Content Types
class ContentTypes {
  static const String cartoon = 'cartoon';
  static const String game = 'game';
  static const String story = 'story';
  static const String quest = 'quest';
}

// Age Ranges
class AgeRanges {
  static const int minAge = 1;
  static const int maxAge = 18;
  static const List<String> groups = ['3-5', '6-8', '9-12', '13+'];
}
