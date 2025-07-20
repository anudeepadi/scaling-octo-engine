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
  
  /// Get detailed platform information for debugging
  static String getPlatformInfo() {
    if (kIsWeb) {
      return 'Web';
    }
    
    if (Platform.isAndroid) {
      return 'Android ${Platform.operatingSystemVersion}';
    }
    
    if (Platform.isIOS) {
      return 'iOS ${Platform.operatingSystemVersion}';
    }
    
    if (Platform.isMacOS) {
      return 'macOS ${Platform.operatingSystemVersion}';
    }
    
    if (Platform.isWindows) {
      return 'Windows ${Platform.operatingSystemVersion}';
    }
    
    if (Platform.isLinux) {
      return 'Linux ${Platform.operatingSystemVersion}';
    }
    
    return 'Unknown ${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  }
  
  /// Transforms any URL that contains localhost to use the appropriate
  /// platform-specific address
  static String transformLocalHostUrl(String url) {
    if (url.contains('localhost')) {
      // For Android emulators, replace localhost with 10.0.2.2
      if (Platform.isAndroid) {
        return url.replaceAll('localhost', '10.0.2.2');
      }
      // For iOS, make sure we're not using 10.0.2.2
      if (Platform.isIOS && url.contains('10.0.2.2')) {
        return url.replaceAll('10.0.2.2', 'localhost');
      }
    }
    
    // Handle ngrok URLs consistently across platforms
    if (url.contains('ngrok.io')) {
      // Ensure we're using https for ngrok URLs
      if (!url.startsWith('https://') && !url.startsWith('http://')) {
        return 'https://$url';
      }
      // Convert http to https for ngrok URLs if needed
      if (url.startsWith('http://')) {
        return url.replaceFirst('http://', 'https://');
      }
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