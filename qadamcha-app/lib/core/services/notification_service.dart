import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../network/api_client.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message: ${message.messageId}');
}

/// Push Notification Service
/// Handles Firebase Cloud Messaging integration
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  ApiClient? _apiClient;
  GlobalKey<NavigatorState>? _navigatorKey;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  final StreamController<RemoteMessage> _messageController =
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onMessage => _messageController.stream;

  /// Configure dependencies (call before initialize)
  void configure({
    required ApiClient apiClient,
    required GlobalKey<NavigatorState> navigatorKey,
  }) {
    _apiClient = apiClient;
    _navigatorKey = navigatorKey;
  }

  /// Initialize notification service
  Future<void> initialize() async {
    // Set background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission (iOS/Web)
    await _requestPermission();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Get FCM token
    await _getFcmToken();

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      print('FCM Token refreshed: $token');
      _sendTokenToBackend(token);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check for initial message (app opened from terminated state)
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// Request notification permission
  Future<void> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('Notification permission: ${settings.authorizationStatus}');
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'qadamcha_channel',
        'Qadamcha Notifications',
        description: 'Qadamcha ilovasi uchun bildirishnomalar',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Get FCM token
  Future<void> _getFcmToken() async {
    _fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $_fcmToken');
    if (_fcmToken != null) {
      _sendTokenToBackend(_fcmToken!);
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message: ${message.notification?.title}');
    _messageController.add(message);

    // Show local notification
    _showLocalNotification(message);
  }

  /// Handle notification tap — navigate based on message data
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.data}');
    _messageController.add(message);

    _navigateByData(message.data);
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'qadamcha_channel',
      'Qadamcha Notifications',
      channelDescription: 'Qadamcha ilovasi uchun bildirishnomalar',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  /// Handle local notification tap — parse payload and navigate
  void _onLocalNotificationTap(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _navigateByData(data);
      } catch (_) {}
    }
  }

  /// Navigate based on notification data type
  void _navigateByData(Map<String, dynamic> data) {
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) return;

    final type = NotificationTypeExtension.fromString(data['type']);
    switch (type) {
      case NotificationType.childActivity:
      case NotificationType.timeLimitWarning:
      case NotificationType.timeLimitReached:
        navigator.pushNamed('/devices');
        break;
      case NotificationType.deviceLinked:
        navigator.pushNamed('/devices');
        break;
      case NotificationType.subscriptionExpiry:
        navigator.pushNamed('/subscription');
        break;
      case NotificationType.newContent:
        navigator.pushNamed('/content');
        break;
      case NotificationType.aiMessage:
        navigator.pushNamed('/ai-chat');
        break;
      case null:
        break;
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }

  /// Send FCM token to backend
  Future<void> _sendTokenToBackend(String token) async {
    if (_apiClient == null) return;
    try {
      await _apiClient!.put('/devices/fcm-token', data: {'fcmToken': token});
      print('FCM token sent to backend');
    } catch (e) {
      print('Failed to send FCM token: $e');
    }
  }

  /// Register token with backend (public API for manual trigger)
  Future<void> registerTokenWithBackend(String userId) async {
    if (_fcmToken == null) return;
    await _sendTokenToBackend(_fcmToken!);
  }

  void dispose() {
    _messageController.close();
  }
}

/// Notification types for the app
enum NotificationType {
  childActivity,      // Child started/stopped using app
  timeLimitWarning,   // Time limit about to expire
  timeLimitReached,   // Time limit reached
  deviceLinked,       // New device linked
  subscriptionExpiry, // Subscription about to expire
  newContent,         // New content available
  aiMessage,          // AI assistant message
}

/// Extension to parse notification type from data
extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.childActivity:
        return 'child_activity';
      case NotificationType.timeLimitWarning:
        return 'time_limit_warning';
      case NotificationType.timeLimitReached:
        return 'time_limit_reached';
      case NotificationType.deviceLinked:
        return 'device_linked';
      case NotificationType.subscriptionExpiry:
        return 'subscription_expiry';
      case NotificationType.newContent:
        return 'new_content';
      case NotificationType.aiMessage:
        return 'ai_message';
    }
  }

  static NotificationType? fromString(String? value) {
    switch (value) {
      case 'child_activity':
        return NotificationType.childActivity;
      case 'time_limit_warning':
        return NotificationType.timeLimitWarning;
      case 'time_limit_reached':
        return NotificationType.timeLimitReached;
      case 'device_linked':
        return NotificationType.deviceLinked;
      case 'subscription_expiry':
        return NotificationType.subscriptionExpiry;
      case 'new_content':
        return NotificationType.newContent;
      case 'ai_message':
        return NotificationType.aiMessage;
      default:
        return null;
    }
  }
}
