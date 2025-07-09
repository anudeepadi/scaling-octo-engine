import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/quitxt_dto.dart';
import 'dash_messaging_service.dart';
import 'notification_service.dart';
import 'dart:developer' as developer;

// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized
  await Firebase.initializeApp();
  developer.log('Handling a background message: ${message.messageId}', name: 'FCM');
  developer.log('Message data: ${message.data}', name: 'FCM');
  
  // Show notification for background messages
  final notificationService = NotificationService();
  await notificationService.showNotificationFromFirebaseMessage(message);
}

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final DashMessagingService _dashMessagingService = DashMessagingService();
  final NotificationService _notificationService = NotificationService();
  
  // Singleton instance
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();
  
  // Get FCM token
  Future<String?> getFcmToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        developer.log('FCM Token: $token', name: 'FCM');
      }
      return token;
    } catch (e) {
      developer.log('Error getting FCM token: $e', name: 'FCM');
      return null;
    }
  }
  
  // Setup messaging handlers
  Future<void> setupMessaging() async {
    // Initialize notification service
    await _notificationService.initialize();
    
    // Request permissions for iOS
    if (Platform.isIOS) {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      developer.log('User granted permission: ${settings.authorizationStatus}', name: 'FCM');
    }
    
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('Got a message whilst in the foreground!', name: 'FCM');
      developer.log('Message data: ${message.data}', name: 'FCM');
      
      // Extract message data
      final Map<String, dynamic> data = message.data;
      final String? messageBody = data['messageBody'];
      
      if (messageBody != null) {
        developer.log('Message body: $messageBody', name: 'FCM');
        
        // Show notification even when app is in foreground
        _notificationService.showNotificationFromFirebaseMessage(message);
      }
      
      // Process message data
      _processMessage(message);
    });
    
    // Handle when app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('A notification was tapped and opened the app!', name: 'FCM');
      developer.log('Message data: ${message.data}', name: 'FCM');
      
      // Process message data
      _processMessage(message);
    });
    
    // Check if the app was opened from a terminated state
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      developer.log('App opened from terminated state by tapping notification', name: 'FCM');
      developer.log('Initial message data: ${initialMessage.data}', name: 'FCM');
      
      // Process initial message data
      _processMessage(initialMessage);
    }
    
    // Listen for token refreshes
    FirebaseMessaging.instance.onTokenRefresh.listen((String token) {
      developer.log('FCM Token refreshed: $token', name: 'FCM');
      // Update token in your server or application state
    });
  }
  
  // Process incoming FCM message
  void _processMessage(RemoteMessage message) {
    try {
      // Extract message data
      final data = message.data;
      
      // Log the exact format received
      developer.log('Processing FCM message: ${data.toString()}', name: 'FCM');
      
      // Check if this is a QuitTXT message (compatible with expected format)
      if (data.containsKey('serverMessageId') && data.containsKey('messageBody')) {
        // Parse into DTO
        final quitxtMessage = QuitxtServerIncomingDto.fromJson(data);
        
        // Forward to DashMessagingService
        _dashMessagingService.handlePushNotification(data);
      } else {
        developer.log('Received FCM message with unexpected format: ${data.toString()}', name: 'FCM');
      }
    } catch (e) {
      developer.log('Error processing FCM message: $e', name: 'FCM');
    }
  }
}