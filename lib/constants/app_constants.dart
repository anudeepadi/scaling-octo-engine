class AppConstants {
  static const String httpProtocol = 'https';
  static const String fullProtocol = 'HTTPS';

  static const bool enableDebugLogging = true;
  static const bool enablePerformanceMonitoring = true;
  static const bool enableOfflinePersistence = true;

  static const int defaultPageSize = 50;
  static const int messageFetchLimit = 100;
  static const int maxRetryAttempts = 3;

  static const int connectionTimeoutSeconds = 8;
  static const int readTimeoutSeconds = 8;

  static const String messagesCollection = 'messages';
  static const String chatSubcollection = 'chat';
}
