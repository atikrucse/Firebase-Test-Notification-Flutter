import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Background message handler - MUST be a top-level function (outside any class)
/// This handles messages when the app is in background or terminated
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Note: You don't need to show a notification here for notification messages
  // Firebase automatically shows them. This is mainly for data-only messages.
  debugPrint('Background message received: ${message.messageId}');
  debugPrint('Message data: ${message.data}');

  if (message.notification != null) {
    debugPrint('Message notification: ${message.notification?.title}');
  }
}

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialize the notification service
  /// Call this after Firebase.initializeApp()
  Future<void> initialize() async {
    // 1. Request permission (required for iOS and Android 13+)
    await _requestPermission();

    // 2. Get and print the FCM token (you'll need this for testing)
    await _getToken();

    // 3. Set up foreground message handler
    _setupForegroundMessageHandler();

    // 4. Set up message open handler (when user taps notification)
    _setupMessageOpenHandler();

    // 5. Handle initial message (if app was opened from terminated state via notification)
    await _handleInitialMessage();

    debugPrint('NotificationService initialized successfully');
  }

  /// Request notification permissions
  Future<void> _requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('Notification permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }
  }

  /// Get the FCM token for this device
  /// You need this token to send targeted notifications
  Future<String?> _getToken() async {
    try {
      String? token = await _messaging.getToken();

      if (token != null) {
        debugPrint('========================================');
        debugPrint('FCM Token: $token');
        debugPrint('========================================');
        debugPrint('Copy this token to send test notifications from Firebase Console');
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token refreshed: $newToken');
        // TODO: Send the new token to your server if needed
      });

      return token;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Handle messages when the app is in foreground
  void _setupForegroundMessageHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message received!');
      debugPrint('Message ID: ${message.messageId}');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Notification title: ${message.notification?.title}');
        debugPrint('Notification body: ${message.notification?.body}');

        // Note: On Android, notification messages are automatically displayed
        // when the app is in foreground if you're using firebase_messaging >= 11.0.0
        // For older versions or custom handling, you might want to use
        // flutter_local_notifications package to show a local notification
      }
    });
  }

  /// Handle when user taps on a notification (app in background)
  void _setupMessageOpenHandler() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification tapped! (App was in background)');
      debugPrint('Message data: ${message.data}');

      // TODO: Navigate to specific screen based on message data
      _handleNotificationTap(message);
    });
  }

  /// Handle initial message if app was opened from terminated state
  Future<void> _handleInitialMessage() async {
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('App opened from terminated state via notification!');
      debugPrint('Message data: ${initialMessage.data}');

      // TODO: Navigate to specific screen based on message data
      _handleNotificationTap(initialMessage);
    }
  }

  /// Handle notification tap - implement your navigation logic here
  void _handleNotificationTap(RemoteMessage message) {
    // Example: Navigate based on message data
    // You can pass data in your notification payload like:
    // { "data": { "screen": "chat", "chatId": "123" } }

    final data = message.data;
    debugPrint('Handling notification tap with data: $data');

    // TODO: Implement navigation logic
    // Example:
    // if (data['screen'] == 'chat') {
    //   Navigator.pushNamed(context, '/chat', arguments: data['chatId']);
    // }
  }

  /// Subscribe to a topic (for topic-based notifications)
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }

  /// Get current FCM token (public method for when you need it later)
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}
