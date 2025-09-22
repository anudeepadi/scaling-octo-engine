import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;

/// Performance monitoring utility for tracking optimization progress
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, Stopwatch> _stopwatches = {};
  final Map<String, List<int>> _metrics = {};
  final Map<String, int> _counters = {};

  // Performance tracking flags
  bool _isEnabled = kDebugMode;
  
  /// Enable or disable performance monitoring
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Start timing an operation
  void startTimer(String operation) {
    if (!_isEnabled) return;
    
    _stopwatches[operation] = Stopwatch()..start();
    developer.log('⏱️ Started timing: $operation', name: 'Performance');
  }

  /// Stop timing an operation and record the result
  int stopTimer(String operation) {
    if (!_isEnabled) return 0;
    
    final stopwatch = _stopwatches[operation];
    if (stopwatch == null) {
      developer.log('⚠️ No timer found for: $operation', name: 'Performance');
      return 0;
    }

    stopwatch.stop();
    final elapsedMs = stopwatch.elapsedMilliseconds;
    
    // Store metric
    _metrics.putIfAbsent(operation, () => []).add(elapsedMs);
    
    developer.log('⏱️ Completed: $operation in ${elapsedMs}ms', name: 'Performance');
    
    // Alert if operation is slow
    _checkPerformanceThresholds(operation, elapsedMs);
    
    return elapsedMs;
  }

  /// Increment a counter metric
  void incrementCounter(String counter, [int amount = 1]) {
    if (!_isEnabled) return;
    
    _counters[counter] = (_counters[counter] ?? 0) + amount;
  }

  /// Get counter value
  int getCounter(String counter) {
    return _counters[counter] ?? 0;
  }

  /// Get average time for an operation
  double getAverageTime(String operation) {
    final times = _metrics[operation];
    if (times == null || times.isEmpty) return 0.0;
    
    return times.reduce((a, b) => a + b) / times.length;
  }

  /// Get latest time for an operation
  int getLatestTime(String operation) {
    final times = _metrics[operation];
    if (times == null || times.isEmpty) return 0;
    
    return times.last;
  }

  /// Check if operation exceeds performance thresholds
  void _checkPerformanceThresholds(String operation, int elapsedMs) {
    final thresholds = {
      'message_sort': 10,           // Message sorting should be <10ms
      'firebase_init': 3000,        // Firebase init should be <3s
      'message_render': 16,         // 60fps = 16ms per frame
      'provider_notify': 5,         // Provider updates should be <5ms
      'image_load': 500,           // Image loading should be <500ms
    };

    final threshold = thresholds[operation];
    if (threshold != null && elapsedMs > threshold) {
      developer.log(
        '🚨 PERFORMANCE ALERT: $operation took ${elapsedMs}ms (threshold: ${threshold}ms)',
        name: 'Performance'
      );
    }
  }

  /// Generate performance report
  String generateReport() {
    if (!_isEnabled) return 'Performance monitoring disabled';

    final buffer = StringBuffer();
    buffer.writeln('📊 PERFORMANCE REPORT');
    buffer.writeln('=' * 50);
    
    // Timing metrics
    buffer.writeln('\n⏱️ TIMING METRICS:');
    _metrics.forEach((operation, times) {
      final avg = getAverageTime(operation);
      final latest = getLatestTime(operation);
      final min = times.reduce((a, b) => a < b ? a : b);
      final max = times.reduce((a, b) => a > b ? a : b);
      
      buffer.writeln('  $operation:');
      buffer.writeln('    Latest: ${latest}ms');
      buffer.writeln('    Average: ${avg.toStringAsFixed(1)}ms');
      buffer.writeln('    Min: ${min}ms, Max: ${max}ms');
      buffer.writeln('    Samples: ${times.length}');
    });

    // Counter metrics
    buffer.writeln('\n📊 COUNTER METRICS:');
    _counters.forEach((counter, value) {
      buffer.writeln('  $counter: $value');
    });

    // Memory info
    buffer.writeln('\n💾 MEMORY INFO:');
    buffer.writeln('  Platform: ${Platform.operatingSystem}');
    
    return buffer.toString();
  }

  /// Log current performance status
  void logStatus() {
    if (!_isEnabled) return;
    
    developer.log(generateReport(), name: 'Performance');
  }

  /// Clear all metrics
  void clearMetrics() {
    _metrics.clear();
    _counters.clear();
    _stopwatches.clear();
    developer.log('🧹 Cleared all performance metrics', name: 'Performance');
  }

  /// Monitor message sorting performance
  void monitorMessageSort(Function sortFunction) {
    startTimer('message_sort');
    sortFunction();
    stopTimer('message_sort');
    incrementCounter('message_sorts');
  }

  /// Monitor provider notifications
  void monitorProviderNotify(Function notifyFunction) {
    startTimer('provider_notify');
    notifyFunction();
    stopTimer('provider_notify');
    incrementCounter('provider_notifications');
  }

  /// Monitor Firebase operations
  Future<T> monitorFirebaseOperation<T>(
    String operation, 
    Future<T> Function() firebaseFunction
  ) async {
    startTimer('firebase_$operation');
    try {
      final result = await firebaseFunction();
      stopTimer('firebase_$operation');
      incrementCounter('firebase_operations');
      return result;
    } catch (e) {
      stopTimer('firebase_$operation');
      incrementCounter('firebase_errors');
      rethrow;
    }
  }

  /// Get optimization progress metrics
  Map<String, dynamic> getOptimizationMetrics() {
    return {
      'message_sort_avg': getAverageTime('message_sort'),
      'firebase_init_time': getLatestTime('firebase_init'),
      'provider_notify_avg': getAverageTime('provider_notify'),
      'total_message_sorts': getCounter('message_sorts'),
      'total_provider_notifications': getCounter('provider_notifications'),
      'firebase_operations': getCounter('firebase_operations'),
      'firebase_errors': getCounter('firebase_errors'),
    };
  }

  /// Check if optimization targets are met
  Map<String, bool> checkOptimizationTargets() {
    return {
      'message_sort_optimized': getAverageTime('message_sort') < 10,
      'firebase_init_optimized': getLatestTime('firebase_init') < 3000,
      'provider_performance_good': getAverageTime('provider_notify') < 5,
      'firebase_reliability_good': getCounter('firebase_errors') == 0,
    };
  }
}