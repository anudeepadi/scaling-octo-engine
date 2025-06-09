import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  english,
  spanish
}

class LocalizationProvider extends ChangeNotifier {
  AppLanguage _currentLanguage = AppLanguage.english;
  final Map<String, Map<String, String>> _translations = {
    'en': {
      // Login Screen
      'sign_in': 'Sign In',
      'username': 'Username',
      'password': 'Password',
      'login': 'LOGIN',
      'google_sign_in': 'Sign in',
      
      // Navigation Drawer
      'profile': 'Profile',
      'chat': 'Chat',
      'exit': 'Exit',
      
      // Profile Screen
      'user': 'User',
      'last_access_time': 'Last access time',
      'sign_in_method': 'Sign in method',
      'user_id': 'User ID',
      'language': 'Language',
      'english': 'English',
      'spanish': 'Spanish',
      'sign_out': 'Sign Out',
      
      // Chat Screen
      'quit_txt_mobile': 'QuitTXT Mobile',
      'type_message': 'Type a message...',
      'send': 'SEND',
      'load_sample_messages': 'Loading sample test messages...',
      
      // Quick Replies
      'better_health': 'Better Health',
      'save_money': 'Save Money',
      'more_energy': 'More Energy',
      
      // Sample Messages
      'welcome_message': 'Welcome to QuitTXT from the UT Health Science Center! Congrats on your decision to quit smoking! See why we think you\'re awesome, Tap pic below',
      'goodbye_message': 'We\'re sorry to see you go. Here\'s a quick tip: Stay strong!',
      'benefits_question': 'Which of these benefits appeals to you the most?',
      'reason_quit': 'Reason #2 to quit smoking while you\'re young: Add a decade to your life and see the rise of fully automated smart homes; who needs to do chores when robots become a common commodity!',
    },
    'es': {
      // Login Screen
      'sign_in': 'Iniciar Sesión',
      'username': 'Nombre de Usuario',
      'password': 'Contraseña',
      'login': 'ENTRAR',
      'google_sign_in': 'Iniciar sesión',
      
      // Navigation Drawer
      'profile': 'Perfil',
      'chat': 'Chat',
      'exit': 'Salir',
      
      // Profile Screen
      'user': 'Usuario',
      'last_access_time': 'Último acceso',
      'sign_in_method': 'Método de inicio de sesión',
      'user_id': 'ID de Usuario',
      'language': 'Idioma',
      'english': 'Inglés',
      'spanish': 'Español',
      'sign_out': 'Cerrar Sesión',
      
      // Chat Screen
      'quit_txt_mobile': 'QuitTXT Móvil',
      'type_message': 'Escribe un mensaje...',
      'send': 'ENVIAR',
      'load_sample_messages': 'Cargando mensajes de muestra...',
      
      // Quick Replies
      'better_health': 'Mejor Salud',
      'save_money': 'Ahorrar Dinero',
      'more_energy': 'Más Energía',
      
      // Sample Messages
      'welcome_message': '¡Bienvenido a QuitTXT del Centro de Ciencias de la Salud UT! ¡Felicidades por tu decisión de dejar de fumar! Mira por qué pensamos que eres increíble, toca la imagen a continuación',
      'goodbye_message': 'Lamentamos verte partir. Aquí hay un consejo rápido: ¡Mantente fuerte!',
      'benefits_question': '¿Cuál de estos beneficios te atrae más?',
      'reason_quit': 'Razón #2 para dejar de fumar mientras eres joven: ¡Añade una década a tu vida y observa el auge de los hogares inteligentes totalmente automatizados; quién necesita hacer tareas domésticas cuando los robots se convierten en una mercancía común!',
    },
  };

  LocalizationProvider() {
    _loadSavedLanguage();
  }
  
  // Getter for current language
  AppLanguage get currentLanguage => _currentLanguage;
  
  // Getter to check if app is in Spanish mode
  bool get isSpanish => _currentLanguage == AppLanguage.spanish;
  
  // Translate a key to current language
  String translate(String key) {
    final languageCode = _currentLanguage == AppLanguage.english ? 'en' : 'es';
    return _translations[languageCode]?[key] ?? key;
  }
  
  // Switch between languages
  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;
    
    _currentLanguage = language;
    await _saveLanguagePreference();
    notifyListeners();
  }
  
  // Toggle between English and Spanish
  Future<void> toggleLanguage() async {
    final newLanguage = isSpanish ? AppLanguage.english : AppLanguage.spanish;
    await setLanguage(newLanguage);
  }
  
  // Load saved language preference
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageIndex = prefs.getInt('language_preference') ?? 0;
      _currentLanguage = AppLanguage.values[languageIndex];
      notifyListeners();
    } catch (e) {
      print('Error loading language preference: $e');
    }
  }
  
  // Save language preference
  Future<void> _saveLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('language_preference', _currentLanguage.index);
    } catch (e) {
      print('Error saving language preference: $e');
    }
  }
}