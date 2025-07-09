import 'package:flutter/foundation.dart';
import '../utils/debug_config.dart';

class DebugConfig {
  static const bool _enableDebugLogging = false; // Set to false to disable all debug logs
  
  /// Whether debug logging is enabled
  static bool get isDebugLoggingEnabled => _enableDebugLogging && kDebugMode;
  
  /// Debug print that only prints when debug logging is enabled
  static void debugPrint(String message) {
    if (isDebugLoggingEnabled) {
      DebugConfig.debugPrint(message);
    }
  }
  
  /// Performance timing debug print
  static void performancePrint(String message) {
    if (isDebugLoggingEnabled) {
      DebugConfig.debugPrint('⏱️ $message');
    }
  }
  
  /// Firebase/messaging debug print
  static void messagingPrint(String message) {
    if (isDebugLoggingEnabled) {
      DebugConfig.debugPrint('📨 $message');
    }
  }
  
  /// Error print (always shown)
  static void errorPrint(String message) {
    DebugConfig.debugPrint('❌ ERROR: $message');
  }
  
  /// Info print (always shown for important information)
  static void infoPrint(String message) {
    DebugConfig.debugPrint('ℹ️ $message');
  }
} 