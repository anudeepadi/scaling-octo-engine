import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/debug_config.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageCodeKey = 'language_code';
  
  Locale _currentLocale = const Locale('en');
  
  Locale get currentLocale => _currentLocale;
  
  // Get current language name for display
  String get currentLanguageName {
    switch (_currentLocale.languageCode) {
      case 'es':
        return 'Español';
      case 'en':
      default:
        return 'English';
    }
  }
  
  LanguageProvider() {
    _loadSavedLanguage();
  }
  
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString(_languageCodeKey);
      
      if (savedLanguageCode != null) {
        _currentLocale = Locale(savedLanguageCode);
        notifyListeners();
      }
    } catch (e) {
      DebugConfig.debugPrint('Error loading saved language: $e');
    }
  }
  
  Future<void> setLanguage(String languageCode) async {
    if (_currentLocale.languageCode == languageCode) return;
    
    try {
      _currentLocale = Locale(languageCode);
      
      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageCodeKey, languageCode);
      
      notifyListeners();
    } catch (e) {
      DebugConfig.debugPrint('Error setting language: $e');
    }
  }
}