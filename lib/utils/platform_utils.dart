import 'dart:io';
import 'package:flutter/foundation.dart';

class PlatformUtils {
  /// Gets the appropriate localhost URL based on platform
  /// - For Android emulators: uses 10.0.2.2 (special IP that routes to host machine)
  /// - For iOS simulators: uses localhost (iOS simulators share network namespace with host)
  /// - For physical devices or web: uses the provided fallback or localhost
  static String getLocalHostUrl(String port, {String path = '', String? fallback}) {
    // If running on web, use the fallback or localhost
    if (kIsWeb) {
      return fallback ?? 'http://localhost:$port$path';
    }
    
    // For Android emulator, use 10.0.2.2 to access host's localhost
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:$port$path';
    }
    
    // For iOS simulator, localhost works directly
    if (Platform.isIOS) {
      return 'http://localhost:$port$path';
    }
    
    // For other platforms (macOS, Windows, Linux)
    return 'http://localhost:$port$path';
  }
  
  /// Transforms any URL that contains localhost to use the appropriate
  /// platform-specific address
  static String transformLocalHostUrl(String url) {
    if (url.contains('localhost') && Platform.isAndroid) {
      return url.replaceAll('localhost', '10.0.2.2');
    }
    return url;
  }
  
  /// Check if we're running in an emulator/simulator
  static bool get isEmulator {
    if (kIsWeb) return false;
    
    // This is a simplified check - in a real app you might need
    // more sophisticated detection
    if (Platform.isAndroid || Platform.isIOS) {
      final deviceModel = Platform.isIOS ? 'Simulator' : 'emulator';
      return Platform.environment.containsKey(deviceModel) || 
             Platform.environment.toString().toLowerCase().contains('emulator');
    }
    
    return false;
  }
} 