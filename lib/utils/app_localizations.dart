import 'package:flutter/material.dart';
import 'dart:async';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  // Helper method to keep the code in the widgets concise
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // Static member to have a simple access to the delegate from the MaterialApp
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  // List of supported languages
  static final List<Locale> supportedLocales = [
    const Locale('en'),
    const Locale('es'),
  ];

  // Translation maps
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Auth screen
      'login_title': 'Sign In',
      'username_hint': 'Username',
      'password_hint': 'Password',
      'login_button': 'LOGIN',
      'google_login': 'Sign in',
      'auth_error': 'Authentication failed',

      // Registration screen
      'register_title': 'Create Account',
      'full_name_hint': 'Full Name',
      'email_hint': 'Email',
      'confirm_password_hint': 'Confirm Password',
      'register_button': 'CREATE ACCOUNT',
      'already_have_account': 'Already have an account?',
      'sign_in_link': 'Sign In',
      'please_enter_name': 'Please enter your name',
      'please_enter_email': 'Please enter your email',
      'invalid_email': 'Please enter a valid email',
      'please_enter_password': 'Please enter a password',
      'password_too_short': 'Password must be at least 6 characters',
      'password_mismatch': 'Passwords do not match',

      // Home screen
      'app_title': 'QuitTXT Mobile',
      'type_message': 'Type a message...',
      'send': 'SEND',

      // Navigation drawer
      'profile': 'Profile',
      'chat': 'Chat',
      'exit': 'Exit',
      
      // Profile screen
      'user': 'User',
      'last_access_time': 'Last access time',
      'sign_in_method': 'Sign in method',
      'user_id': 'User ID',
      'language': 'Language',
      'sign_out': 'Sign Out',
      
      // Chat messages
      'quit_ready': 'Are you ready to quit smoking tomorrow?',
      'yes_do_it': 'Yes, let\'s do it!',
      'not_yet': 'No, not yet',
      'loading_sample': 'Loading sample test messages...',
      'better_health': 'Better Health',
      'save_money': 'Save Money',
      'more_energy': 'More Energy',
      
      // Clear messages feature
      'clear_all_messages': 'Clear All Messages',
      'clear_messages_title': 'Clear All Messages',
      'clear_messages_confirmation': 'Are you sure you want to delete all messages? This action cannot be undone.',
      'cancel': 'Cancel',
      'clear': 'Clear',
      'messages_cleared': 'All messages have been cleared',
      
      // Error messages
      'error': 'Error',
      'ok': 'OK',
    },
    'es': {
      // Auth screen
      'login_title': 'Iniciar Sesión',
      'username_hint': 'Nombre de usuario',
      'password_hint': 'Contraseña',
      'login_button': 'ENTRAR',
      'google_login': 'Iniciar con Google',
      'auth_error': 'Autenticación fallida',

      // Registration screen
      'register_title': 'Crear Cuenta',
      'full_name_hint': 'Nombre Completo',
      'email_hint': 'Correo Electrónico',
      'confirm_password_hint': 'Confirmar Contraseña',
      'register_button': 'CREAR CUENTA',
      'already_have_account': '¿Ya tienes una cuenta?',
      'sign_in_link': 'Iniciar Sesión',
      'please_enter_name': 'Por favor ingresa tu nombre',
      'please_enter_email': 'Por favor ingresa tu correo electrónico',
      'invalid_email': 'Por favor ingresa un correo electrónico válido',
      'please_enter_password': 'Por favor ingresa una contraseña',
      'password_too_short': 'La contraseña debe tener al menos 6 caracteres',
      'password_mismatch': 'Las contraseñas no coinciden',

      // Home screen
      'app_title': 'QuitTXT Móvil',
      'type_message': 'Escribe un mensaje...',
      'send': 'ENVIAR',

      // Navigation drawer
      'profile': 'Perfil',
      'chat': 'Chat',
      'exit': 'Salir',
      
      // Profile screen
      'user': 'Usuario',
      'last_access_time': 'Último acceso',
      'sign_in_method': 'Método de inicio de sesión',
      'user_id': 'ID de usuario',
      'language': 'Idioma',
      'sign_out': 'Cerrar Sesión',
      
      // Chat messages
      'quit_ready': '¿Estás listo para dejar de fumar mañana?',
      'yes_do_it': '¡Sí, hagámoslo!',
      'not_yet': 'No, todavía no',
      'loading_sample': 'Cargando mensajes de prueba...',
      'better_health': 'Mejor Salud',
      'save_money': 'Ahorrar Dinero',
      'more_energy': 'Más Energía',
      
      // Clear messages feature
      'clear_all_messages': 'Borrar Todos los Mensajes',
      'clear_messages_title': 'Borrar Todos los Mensajes',
      'clear_messages_confirmation': '¿Estás seguro de que deseas eliminar todos los mensajes? Esta acción no se puede deshacer.',
      'cancel': 'Cancelar',
      'clear': 'Borrar',
      'messages_cleared': 'Todos los mensajes han sido borrados',
      
      // Error messages
      'error': 'Error',
      'ok': 'Aceptar',
    },
  };

  String get appTitle => _localizedValues[locale.languageCode]?['app_title'] ?? 'QuitTXT Mobile';
  
  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? 
           _localizedValues['en']?[key] ?? 
           key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'es'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return Future.value(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}