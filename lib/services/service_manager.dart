import 'package:flutter/foundation.dart';
import 'dash_messaging_service.dart';

// Abstract class that defines what a messaging service should implement
abstract class MessagingService {
  bool get isInitialized;
  Stream<dynamic> get messageStream;
  Future<void> initialize(String userId, String? fcmToken);
  Future<void> sendMessage(String message, {Map<String, dynamic>? metadata});
}

class ServiceManager extends ChangeNotifier {
  // Available services
  final DashMessagingService _dashService = DashMessagingService();
  
  // Current active service
  MessagingService _currentService;
  String _serviceDisplayName = "Dash";
  
  // Constructor
  ServiceManager() : _currentService = DashMessagingService();
  
  // Getters
  MessagingService get currentService => _currentService;
  String get serviceDisplayName => _serviceDisplayName;
  
  // Initialize with a user ID and FCM token
  Future<void> initialize(String userId, String? fcmToken) async {
    await _currentService.initialize(userId, fcmToken);
    notifyListeners();
  }
  
  // Switch to Dash service
  Future<void> useDash() async {
    if (_currentService is! DashMessagingService) {
      _currentService = _dashService;
      _serviceDisplayName = "Dash";
      notifyListeners();
    }
  }
  
  // Switch to Gemini service (placeholder for future implementation)
  Future<void> useGemini() async {
    // This would be implemented when Gemini service is available
    // For now, we'll just notify that it's not implemented
    print("Gemini service not implemented yet");
    notifyListeners();
  }
  
  // Toggle between available services
  Future<void> toggleService() async {
    if (_currentService is DashMessagingService) {
      await useGemini();
    } else {
      await useDash();
    }
  }
} 