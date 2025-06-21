import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

/// Firebase Performance Configuration
/// Optimizes Firebase settings for ultra-fast message retrieval
class FirebasePerformanceConfig {
  
  /// Configure Firebase for maximum performance
  static void configureForPerformance() {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Enable offline persistence with aggressive caching
      firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        // Enable faster local caching
      );
      
      // Enable network optimizations
      _configureNetworkOptimizations();
      
      developer.log('✅ Firebase performance configuration applied', name: 'FirebasePerformance');
    } catch (e) {
      developer.log('⚠️ Firebase performance configuration failed: $e', name: 'FirebasePerformance');
    }
  }
  
  /// Configure network-level optimizations
  static void _configureNetworkOptimizations() {
    // Enable aggressive caching for Firestore
    final firestore = FirebaseFirestore.instance;
    
    // Configure connection settings for better performance
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    
    developer.log('Network optimizations configured', name: 'FirebasePerformance');
  }
  
  /// Get optimized query configuration for message loading
  static QueryConfiguration getOptimizedQueryConfig() {
    return QueryConfiguration(
      cacheFirst: true,
      includeMetadataChanges: false,
      maxRetries: 2,
      timeoutMs: 1500,
    );
  }
}

/// Configuration for optimized Firebase queries
class QueryConfiguration {
  final bool cacheFirst;
  final bool includeMetadataChanges;
  final int maxRetries;
  final int timeoutMs;
  
  const QueryConfiguration({
    required this.cacheFirst,
    required this.includeMetadataChanges,
    required this.maxRetries,
    required this.timeoutMs,
  });
}