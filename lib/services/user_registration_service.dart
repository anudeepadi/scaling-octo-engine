import 'dart:convert';
import 'package:http/http.dart' as http;

class UserRegistrationService {
  static const String _registrationEndpoint = '/api/register-user';

  static Future<bool> registerUser({
    required String userId,
    required String serverUrl,
    String? fcmToken,
    String? email,
  }) async {
    try {
      final url = serverUrl.replaceAll('/scheduler/mobile-app', _registrationEndpoint);

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
          return http.Response('{"error": "timeout"}', 408);
        },
      );

      if (response.statusCode == 200 || response.statusCode == 404) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

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
        return data['exists'] == true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}
