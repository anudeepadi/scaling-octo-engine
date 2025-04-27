import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/quitxt_dto.dart';
import 'dash_messaging_service.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final DashMessagingService _dashMessagingService = DashMessagingService();
  
  // Singleton instance
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();
  
  // Get FCM token
  Future<String?> getFcmToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }
  
  // Setup messaging handlers
  Future<void> setupMessaging() async {
    // Request permissions for iOS
    if (!kIsWeb) {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      print('User granted permission: ${settings.authorizationStatus}');
    }
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Handle messages received when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');
      
      if (message.notification != null) {
        print('Message also contained a notification:');
        print('Title: ${message.notification!.title}');
        print('Body: ${message.notification!.body}');
      }
      
      // Process message data
      _processMessage(message);
    });
    
    // Handle when app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A notification was tapped and opened the app!');
      print('Message data: ${message.data}');
      
      // Process message data
      _processMessage(message);
    });
    
    // Check if the app was opened from a terminated state
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from terminated state by tapping notification');
      print('Initial message data: ${initialMessage.data}');
      
      // Process initial message data
      _processMessage(initialMessage);
    }
  }
  
  // Process incoming FCM message
  void _processMessage(RemoteMessage message) {
    try {
      // Extract message data
      final data = message.data;
      
      // Check if this is a QuitTXT message
      if (data.containsKey('serverMessageId') && data.containsKey('messageBody')) {
        // Parse into DTO
        final quitxtMessage = QuitxtServerIncomingDto.fromJson(data);
        
        // Forward to DashMessagingService
        _dashMessagingService.handlePushNotification(data);
      }
    } catch (e) {
      print('Error processing FCM message: $e');
    }
  }
}

// This is required for handling background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize necessary services for background processing
  print('Handling a background message: ${message.messageId}');
  
  // The message should be stored and processed when the app is opened
  // Or you could initialize Firebase and process the message here
}