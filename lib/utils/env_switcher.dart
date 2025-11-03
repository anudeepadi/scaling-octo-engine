import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/debug_config.dart';
import 'dart:async' show TimeoutException;

enum Environment {
  development,
  production,
}

class EnvSwitcher {
  static Future<void> switchEnvironment(Environment env) async {
    try {
      String fileName;
      switch (env) {
        case Environment.development:
          fileName = '.env.development';
          break;
        case Environment.production:
          fileName = '.env.production';
          break;
      }

      try {
        await dotenv.load(fileName: fileName, mergeWith: {}).timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            DebugConfig.debugPrint('Loading $fileName timed out, using defaults');
            throw TimeoutException('Loading $fileName timed out');
          },
        );
      } catch (e) {
        DebugConfig.debugPrint('Could not load $fileName: $e');
        if (env == Environment.development) {
          dotenv.env['SERVER_URL'] = 'http://localhost:8080';
          dotenv.env['ENV'] = 'development';
        } else {
          dotenv.env['SERVER_URL'] = 'https://production-server.com';
          dotenv.env['ENV'] = 'production';
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_env', env.toString());

      DebugConfig.debugPrint('Switched to ${env.toString()} environment');
    } catch (e) {
      DebugConfig.debugPrint('Error switching environment: $e');
    }
  }

  static Future<Environment> getCurrentEnvironment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentEnv = prefs.getString('current_env');

      if (currentEnv == Environment.production.toString()) {
        return Environment.production;
      }

      return Environment.development;
    } catch (e) {
      DebugConfig.debugPrint('Error getting current environment: $e');
      return Environment.development;
    }
  }

  static bool isProduction() {
    return dotenv.env['ENV'] == 'production';
  }

  static bool isDevelopment() {
    return dotenv.env['ENV'] == 'development';
  }

  static String getServerUrl() {
    return dotenv.env['SERVER_URL'] ?? 'http://localhost:8080';
  }
}
