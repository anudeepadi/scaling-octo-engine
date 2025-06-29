import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer' as developer;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Android initialization
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize the plugin
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permissions for Android 13+
      if (Platform.isAndroid) {
        await _requestAndroidPermissions();
      }

      // Create notification channel for Android
      await _createNotificationChannel();

      _isInitialized = true;
      developer.log('NotificationService initialized successfully', name: 'Notifications');
    } catch (e) {
      developer.log('Failed to initialize NotificationService: $e', name: 'Notifications');
    }
  }

  /// Request notification permissions for Android 13+
  Future<void> _requestAndroidPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      final bool? granted = await androidImplementation?.requestNotificationsPermission();
      developer.log('Android notification permission granted: $granted', name: 'Notifications');
    }
  }

  /// Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'quitxt_messages', // Channel ID
        'QuitTXT Messages', // Channel name
        description: 'Notifications for QuitTXT messages',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.createNotificationChannel(channel);
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    developer.log('Notification tapped: ${notificationResponse.payload}', name: 'Notifications');
    // TODO: Navigate to specific chat or message
    // You can add navigation logic here to open the app to the relevant chat
  }

  /// Show a notification for a new message
  Future<void> showMessageNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'quitxt_messages',
        'QuitTXT Messages',
        channelDescription: 'Notifications for QuitTXT messages',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.message,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000), // Unique ID
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      developer.log('Notification shown: $title - $body', name: 'Notifications');
    } catch (e) {
      developer.log('Failed to show notification: $e', name: 'Notifications');
    }
  }

  /// Show notification from Firebase message
  Future<void> showNotificationFromFirebaseMessage(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    // Extract title and body
    String title = notification?.title ?? 'QuitTXT';
    String body = notification?.body ?? data['messageBody'] ?? 'New message received';

    // Create payload with message data
    String payload = message.messageId ?? '';

    await showMessageNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }
} 