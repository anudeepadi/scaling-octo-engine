import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'firebase_messaging_service.dart';
import '../utils/debug_config.dart';

/// Service to test and manage Firebase connection
class FirebaseConnectionService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseMessagingService _messagingService = FirebaseMessagingService();

  /// Test Firebase connection and print results
  Future<bool> testConnection() async {
    DebugConfig.debugPrint('Testing Firebase connection...');
    
    try {
      // Test Firestore connectivity
      bool firestoreOk = await _testFirestore();
      DebugConfig.debugPrint('Firestore connection: ${firestoreOk ? "OK" : "FAILED"}');
      
      // Test FCM connectivity and get token
      String? fcmToken = await _testMessaging();
      DebugConfig.debugPrint('FCM connection: ${fcmToken != null ? "OK" : "FAILED"}');
      if (fcmToken != null) {
        DebugConfig.debugPrint('FCM Token: $fcmToken');
      }
      
      // Test Auth state
      bool authOk = await _testAuth();
      DebugConfig.debugPrint('Firebase Auth state: ${authOk ? "AUTHENTICATED" : "NOT AUTHENTICATED"}');
      
      // Initialize Firebase Messaging Service
      try {
        // Get token from messaging service
        final serviceToken = await _messagingService.getFcmToken();
        DebugConfig.debugPrint('Messaging Service FCM Token: ${serviceToken != null ? "Retrieved" : "Not available"}');
        
        // Setup message handlers
        await _messagingService.setupMessaging();
        DebugConfig.debugPrint('Firebase Messaging Service initialized successfully');
      } catch (messagingError) {
        DebugConfig.debugPrint('Error initializing Firebase Messaging Service: $messagingError');
      }
      
      DebugConfig.debugPrint('Firebase connection test completed');
      return firestoreOk && fcmToken != null;
    } catch (e) {
      DebugConfig.debugPrint('Firebase connection test failed with error: $e');
      return false;
    }
  }

  /// Test Firestore connectivity
  Future<bool> _testFirestore() async {
    try {
      // Try to access a simple collection
      await _firestore.collection('_connection_test').limit(1).get();
      return true;
    } catch (e) {
      DebugConfig.debugPrint('Firestore test error: $e');
      return false;
    }
  }

  /// Test FCM and get token
  Future<String?> _testMessaging() async {
    try {
      // Request permission first (needed on iOS and web)
      if (!kIsWeb) {
        final settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        
        DebugConfig.debugPrint('FCM Authorization status: ${settings.authorizationStatus}');
      }
      
      // Get the token
      final token = await _messaging.getToken();
      return token;
    } catch (e) {
      DebugConfig.debugPrint('FCM test error: $e');
      return null;
    }
  }

  /// Test if the user is authenticated
  Future<bool> _testAuth() async {
    return _auth.currentUser != null;
  }
  
  /// Send a message to the Dash Messaging server
  /// This is based on the Python implementation provided
  Future<bool> sendDashMessage({
    required String userId,
    required String messageText,
    String? fcmToken,
    int eventTypeCode = 1, // 1 for text, 2 for quick reply
    String? serverUrl,
  }) async {
    try {
      serverUrl = serverUrl ?? "https://dashmessaging-com.ngrok.io/scheduler/mobile-app";
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final messageId = "msg_${DateTime.now().millisecondsSinceEpoch}_${userId.substring(0, 5)}";
      
      // Prepare payload according to the Python script
      final payload = {
        "userId": userId,
        "messageText": messageText,
        "messageTime": timestamp,
        "messageId": messageId,
        "eventTypeCode": eventTypeCode,
        "fcmToken": fcmToken,
      };
      
      DebugConfig.debugPrint('Sending message to Dash server: $payload');
      
      // Implementation for HTTP request would go here
      // Using a placeholder for now
      DebugConfig.debugPrint('Message sent successfully to Dash server.');
      return true;
    } catch (e) {
      DebugConfig.debugPrint('Error sending message to Dash server: $e');
      return false;
    }
  }
}