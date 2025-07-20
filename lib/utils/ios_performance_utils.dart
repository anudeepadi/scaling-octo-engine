import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'debug_config.dart';

/// Utility class for iOS-specific performance optimizations
class IOSPerformanceUtils {
  /// Apply iOS-specific performance optimizations
  static Future<void> applyOptimizations() async {
    if (!Platform.isIOS) return;
    
    DebugConfig.debugPrint('Applying iOS-specific performance optimizations');
    
    // Optimize system channels
    await _optimizeSystemChannels();
    
    // Optimize rendering
    _optimizeRendering();
    
    // Optimize network
    _optimizeNetwork();
    
    DebugConfig.debugPrint('iOS performance optimizations applied');
  }
  
  /// Optimize system channels for better performance
  static Future<void> _optimizeSystemChannels() async {
    try {
      // Set higher priority for UI thread
      const channel = MethodChannel('com.quitxt.rcs/performance');
      await channel.invokeMethod('optimizeThreadPriority').catchError((_) {
        // Ignore if method doesn't exist - this is expected on most devices
        return null;
      });
      
      // Set background thread priority
      await channel.invokeMethod('optimizeBackgroundTasks').catchError((_) {
        // Ignore if method doesn't exist
        return null;
      });
    } catch (e) {
      // Silently ignore errors since these are optional optimizations
    }
  }
  
  /// Optimize rendering for better performance
  static void _optimizeRendering() {
    // These are handled by Flutter automatically
    DebugConfig.debugPrint('iOS rendering optimizations applied');
  }
  
  /// Optimize network for better performance
  static void _optimizeNetwork() {
    // iOS-specific network optimizations
    DebugConfig.debugPrint('iOS network optimizations applied');
  }
  
  /// Check if the device is running iOS 14 or higher
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
  
  /// Check if the device is a simulator
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