import 'package:flutter/foundation.dart';
import 'dart:convert';

class DebugConfig {
  static const bool _enableDebugLogging = true; // Set to false to disable all debug logs
  
  /// Whether debug logging is enabled
  static bool get isDebugLoggingEnabled => _enableDebugLogging && kDebugMode;
  
  /// Debug print that only prints when debug logging is enabled
  static void debugPrint(String message) {
    if (isDebugLoggingEnabled) {
      // ignore: avoid_print
      print(message);
    }
  }
  
  /// Performance timing debug print
  static void performancePrint(String message) {
    if (isDebugLoggingEnabled) {
      // ignore: avoid_print
      print('⏱️ $message');
    }
  }
  
  /// Firebase/messaging debug print
  static void messagingPrint(String message) {
    if (isDebugLoggingEnabled) {
      // ignore: avoid_print
      print('📨 $message');
    }
  }

  /// JSON pretty print (always shown for better debugging)
  static void jsonPrint(String label, dynamic jsonData) {
    // Always show JSON data regardless of debug setting
    try {
      final encoder = JsonEncoder.withIndent('  ');
      final prettyJson = encoder.convert(jsonData);
      
      // ignore: avoid_print
      print('\n📋 $label:');
      
      // ignore: avoid_print
      print('╔════════════════════════════════════════════');
      
      // Print each line with a border
      for (var line in prettyJson.split('\n')) {
        // ignore: avoid_print
        print('║ $line');
      }
      
      // ignore: avoid_print
      print('╚════════════════════════════════════════════\n');
    } catch (e) {
      // If there's an error formatting the JSON, fallback to standard toString()
      // ignore: avoid_print
      print('\n📋 $label (raw): ${jsonData.toString()}\n');
    }
  }
  
  /// Error print (always shown)
  static void errorPrint(String message) {
    // ignore: avoid_print
    print('❌ ERROR: $message');
  }
  
  /// Info print (always shown for important information)
  static void infoPrint(String message) {
    // ignore: avoid_print
    print('ℹ️ $message');
  }
} 