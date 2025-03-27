import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Enum to represent the available messaging services
enum MessagingService {
  gemini,
  dash,
}

class ServiceManager with ChangeNotifier {
  static const String _prefsKey = 'selected_messaging_service';
  MessagingService _currentService = MessagingService.gemini; // Default to Gemini
  
  MessagingService get currentService => _currentService;
  
  // Constructor loads the saved preference
  ServiceManager() {
    _loadSavedService();
  }
  
  // Load the saved service preference
  Future<void> _loadSavedService() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedService = prefs.getString(_prefsKey);
      
      if (savedService != null) {
        if (savedService == 'dash') {
          _currentService = MessagingService.dash;
        } else {
          _currentService = MessagingService.gemini;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading saved service: $e');
    }
  }
  
  // Switch to Gemini service
  Future<void> useGemini() async {
    if (_currentService != MessagingService.gemini) {
      _currentService = MessagingService.gemini;
      await _saveServicePreference();
      notifyListeners();
    }
  }
  
  // Switch to Dash Messaging service
  Future<void> useDash() async {
    if (_currentService != MessagingService.dash) {
      _currentService = MessagingService.dash;
      await _saveServicePreference();
      notifyListeners();
    }
  }
  
  // Toggle between services
  Future<void> toggleService() async {
    if (_currentService == MessagingService.gemini) {
      await useDash();
    } else {
      await useGemini();
    }
  }
  
  // Save the current service preference
  Future<void> _saveServicePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey, 
        _currentService == MessagingService.gemini ? 'gemini' : 'dash'
      );
    } catch (e) {
      debugPrint('Error saving service preference: $e');
    }
  }
  
  // Get the display name of the current service
  String get serviceDisplayName {
    switch (_currentService) {
      case MessagingService.gemini:
        return 'Gemini';
      case MessagingService.dash:
        return 'Dash Messaging';
    }
  }
}