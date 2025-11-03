import 'dart:io';
import 'package:flutter/services.dart';

class IOSPerformanceUtils {
  static Future<void> applyOptimizations() async {
    if (!Platform.isIOS) return;

    await _optimizeSystemChannels();
  }

  static Future<void> _optimizeSystemChannels() async {
    try {
      const channel = MethodChannel('com.quitxt.rcs/performance');
      await channel.invokeMethod('optimizeThreadPriority').catchError((_) => null);
      await channel.invokeMethod('optimizeBackgroundTasks').catchError((_) => null);
    } catch (e) {
      // Silently ignore errors since these are optional optimizations
    }
  }

  static bool get isIOS14OrHigher {
    if (!Platform.isIOS) return false;

    try {
      final version = Platform.operatingSystemVersion;
      final match = RegExp(r'(\d+)').firstMatch(version);
      if (match != null) {
        final majorVersion = int.tryParse(match.group(1) ?? '0') ?? 0;
        return majorVersion >= 14;
      }
    } catch (e) {
      // Ignore parsing errors
    }

    return false;
  }

  static bool get isSimulator {
    if (!Platform.isIOS) return false;

    try {
      return Platform.environment.containsKey('SIMULATOR_DEVICE_NAME') ||
             Platform.environment.toString().toLowerCase().contains('simulator');
    } catch (e) {
      return false;
    }
  }
}
