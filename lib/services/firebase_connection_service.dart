import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'firebase_messaging_service.dart';

class FirebaseConnectionService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseMessagingService _messagingService = FirebaseMessagingService();

  Future<bool> testConnection() async {
    try {
      bool firestoreOk = await _testFirestore();
      String? fcmToken = await _testMessaging();
      bool authOk = await _testAuth();

      try {
        final serviceToken = await _messagingService.getFcmToken();
        await _messagingService.setupMessaging();
      } catch (e) {
        debugPrint('Error initializing messaging service: $e');
      }

      return firestoreOk && fcmToken != null;
    } catch (e) {
      debugPrint('Connection test failed: $e');
      return false;
    }
  }

  Future<bool> _testFirestore() async {
    try {
      await _firestore.collection('_connection_test').limit(1).get();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> _testMessaging() async {
    try {
      if (!kIsWeb) {
        await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
      }

      final token = await _messaging.getToken();
      return token;
    } catch (e) {
      return null;
    }
  }

  Future<bool> _testAuth() async {
    return _auth.currentUser != null;
  }

  Future<bool> sendDashMessage({
    required String userId,
    required String messageText,
    String? fcmToken,
    int eventTypeCode = 1,
    String? serverUrl,
  }) async {
    try {
      serverUrl = serverUrl ?? "https://demo-server.example.com/api/mobile";
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final messageId =
          "msg_${DateTime.now().millisecondsSinceEpoch}_${userId.substring(0, 5)}";

      final payload = {
        "userId": userId,
        "messageText": messageText,
        "messageTime": timestamp,
        "messageId": messageId,
        "eventTypeCode": eventTypeCode,
        "fcmToken": fcmToken,
      };

      return true;
    } catch (e) {
      return false;
    }
  }
}
