import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dash_messaging_service.dart';
import 'notification_service.dart';
import 'dart:developer' as developer;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final notificationService = NotificationService();
  await notificationService.showNotificationFromFirebaseMessage(message);
}

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final DashMessagingService _dashMessagingService = DashMessagingService();
  final NotificationService _notificationService = NotificationService();

  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  Future<String?> getFcmToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      return token;
    } catch (e) {
      developer.log('Error getting FCM token: $e', name: 'FCM');
      return null;
    }
  }

  Future<void> setupMessaging() async {
    await _notificationService.initialize();

    if (Platform.isIOS) {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final Map<String, dynamic> data = message.data;
      final String? messageBody = data['messageBody'];

      if (messageBody != null) {
        _notificationService.showNotificationFromFirebaseMessage(message);
      }

      _processMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _processMessage(message);
    });

    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _processMessage(initialMessage);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((String token) {
      developer.log('FCM Token refreshed', name: 'FCM');
    });
  }

  void _processMessage(RemoteMessage message) {
    try {
      final data = message.data;

      if (data.containsKey('serverMessageId') &&
          data.containsKey('messageBody')) {
        _dashMessagingService.handlePushNotification(data);
      }
    } catch (e) {
      developer.log('Error processing FCM message: $e', name: 'FCM');
    }
  }
}
