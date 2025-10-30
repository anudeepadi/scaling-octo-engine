import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/debug_config.dart';

/// Service to register users with the backend server
/// This ensures users exist in the backend database before sending messages
class UserRegistrationService {
  static const String _registrationEndpoint = '/api/register-user';

  /// Register a user with the backend server
  /// This should be called after Firebase authentication succeeds
  static Future<bool> registerUser({
    required String userId,
    required String serverUrl,
    String? fcmToken,
    String? email,
  }) async {
    try {
      final url = serverUrl.replaceAll('/scheduler/mobile-app', _registrationEndpoint);

      DebugConfig.debugPrint('[UserRegistration] Registering user with backend: $userId');
      DebugConfig.debugPrint('[UserRegistration] Server URL: $url');

      final requestBody = {
        'userId': userId,
        'fcmToken': fcmToken ?? '',
        'email': email ?? '',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await http
          .post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          DebugConfig.debugPrint('[UserRegistration] ⚠️ Registration request timeout');
          return http.Response('{"error": "timeout"}', 408);
        },
      );

      if (response.statusCode == 200) {
        DebugConfig.debugPrint('[UserRegistration] ✅ User registered successfully');
        return true;
      } else if (response.statusCode == 404) {
        // Endpoint doesn't exist yet on backend - this is expected during transition
        DebugConfig.debugPrint('[UserRegistration] ⚠️ Registration endpoint not found (404)');
        DebugConfig.debugPrint('[UserRegistration] This is expected if backend hasn\'t implemented /api/register-user yet');
        // Return true to not block user - they can still try sending messages
        return true;
      } else {
        DebugConfig.debugPrint('[UserRegistration] ❌ Registration failed with status: ${response.statusCode}');
        DebugConfig.debugPrint('[UserRegistration] Response: ${response.body}');
        return false;
      }
    } catch (e) {
      DebugConfig.debugPrint('[UserRegistration] ❌ Registration error: $e');
      // Don't block user if registration fails - backend might handle unregistered users
      return false;
    }
  }

  /// Check if a user is registered in the backend
  /// Returns true if user exists, false otherwise
  static Future<bool> checkUserExists({
    required String userId,
    required String serverUrl,
  }) async {
    try {
      final url = serverUrl.replaceAll('/scheduler/mobile-app', '/api/check-user');

      final response = await http
          .get(
        Uri.parse('$url?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final exists = data['exists'] == true;
        DebugConfig.debugPrint('[UserRegistration] User exists check: $exists');
        return exists;
      } else if (response.statusCode == 404) {
        // Endpoint doesn't exist - assume user might not be registered
        DebugConfig.debugPrint('[UserRegistration] Check user endpoint not found');
        return false;
      }

      return false;
    } catch (e) {
      DebugConfig.debugPrint('[UserRegistration] Error checking user: $e');
      return false;
    }
  }
}
