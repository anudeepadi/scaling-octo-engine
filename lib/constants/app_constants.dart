/// App-wide constants used throughout the application
class AppConstants {
  // Server protocol
  static const String httpProtocol = 'https';
  static const String fullProtocol = 'HTTPS';
  
  // Feature flags
  static const bool enableDebugLogging = true;
  static const bool enablePerformanceMonitoring = true;
  static const bool enableOfflinePersistence = true;
  
  // Messaging constants
  static const int defaultPageSize = 50;
  static const int messageFetchLimit = 100;
  static const int maxRetryAttempts = 3;
  
  // Timeouts
  static const int connectionTimeoutSeconds = 8;
  static const int readTimeoutSeconds = 8;
  
  // Firebase collection paths
  static const String messagesCollection = 'messages';
  static const String chatSubcollection = 'chat';
} 