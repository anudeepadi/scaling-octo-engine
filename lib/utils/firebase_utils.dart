import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

// Simplified FirebaseUtils that works without Firebase dependencies
class FirebaseUtils {
  // Get the current user ID - demo implementation
  static Future<String?> getCurrentUserId() async {
    // Return a demo user ID
    return 'demo_user_id';
  }

  // Get the FCM token for push notifications - demo implementation
  static Future<String?> getFCMToken() async {
    try {
      // Try to get the token from preferences first
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('fcm_token');
      
      // If not available, create a dummy token
      if (token == null || token.isEmpty) {
        token = 'demo_fcm_token_${DateTime.now().millisecondsSinceEpoch}';
        
        // Save the token to preferences
        await prefs.setString('fcm_token', token);
      }
      
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return 'demo_fcm_token_fallback';
    }
  }
  
  // Save the FCM token - demo implementation
  static Future<void> saveFCMToken(String token) async {
    try {
      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }
}