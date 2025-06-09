import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      
      // Load the appropriate environment file
      await dotenv.load(fileName: fileName, mergeWith: {});
      
      // Save the current environment to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_env', env.toString());
      
      print('Switched to ${env.toString()} environment');
      print('SERVER_URL: ${dotenv.env['SERVER_URL']}');
      
      // You can add app restart logic here if needed
    } catch (e) {
      print('Error switching environment: $e');
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
      print('Error getting current environment: $e');
      return Environment.development; // Default to development
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