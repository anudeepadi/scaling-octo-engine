import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage Firebase Cloud Messaging
class FirebaseMessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  // Key for storing FCM token in shared preferences
  static const String fcmTokenKey = 'fcm_token';
  
  // Get the FCM token
  Future<String?> getFcmToken() async {
    try {
      // Request permission first (needed on iOS and web)
      if (!kIsWeb) {
        if (Platform.isIOS) {
          final settings = await _messaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );
          
          print('FCM Authorization status: ${settings.authorizationStatus}');
          if (settings.authorizationStatus != AuthorizationStatus.authorized) {
            print('FCM permission not granted');
            return null;
          }
        }
      }
      
      // Try to get token from shared preferences first
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(fcmTokenKey);
      
      if (savedToken != null && savedToken.isNotEmpty) {
        print('Using saved FCM token: ${_maskToken(savedToken)}');
        return savedToken;
      }
      
      // Get a new token
      final token = await _messaging.getToken();
      if (token != null) {
        // Save the token to shared preferences
        await prefs.setString(fcmTokenKey, token);
        print('FCM token generated and saved: ${_maskToken(token)}');
      }
      
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }
  
  // Set up FCM message handlers
  Future<void> setupMessaging() async {
    try {
      // Handle messages when app is in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print('Message also contained a notification:');
          print('Title: ${message.notification!.title}');
          print('Body: ${message.notification!.body}');
        }
        
        // Here you would process the message and add it to your chat provider
      });
      
      // Get initial message if app was opened from a notification
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        print('App opened from notification with data: ${initialMessage.data}');
        // Process the initial message
      }
      
      // Handle when app is opened from a background notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('App opened from background notification with data: ${message.data}');
        // Process the message
      });
      
      print('FCM messaging handlers setup complete');
    } catch (e) {
      print('Error setting up FCM message handlers: $e');
    }
  }
  
  // Delete the FCM token
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      
      // Remove from shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(fcmTokenKey);
      
      print('FCM token deleted');
    } catch (e) {
      print('Error deleting FCM token: $e');
    }
  }
  
  // Mask token for display in logs (security best practice)
  String _maskToken(String token) {
    if (token.length <= 8) return 'XXXX';
    
    final start = token.substring(0, 4);
    final end = token.substring(token.length - 4);
    return '$start....$end';
  }
}