import 'package:flutter/foundation.dart';

class DebugConfig {
  static const bool _enableDebugLogging = true;

  static bool get isDebugLoggingEnabled => _enableDebugLogging && kDebugMode;

  static void debugPrint(String message) {
    if (isDebugLoggingEnabled) {
      // ignore: avoid_print
      print(message);
    }
  }
}
