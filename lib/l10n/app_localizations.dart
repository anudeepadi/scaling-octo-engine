import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  Map<String, String> _translations = {};
  
  AppLocalizations(this.locale);
  
  // Helper method to get translations
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
  
  // Delegate for localization
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
  
  // Load translations from JSON files
  Future<void> load() async {
    String jsonString = await rootBundle.loadString('lib/l10n/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    _translations = jsonMap.map((key, value) => MapEntry(key, value.toString()));
  }
  
  // Get a translated string
  String translate(String key) {
    return _translations[key] ?? key;
  }
  
  // Function to test if translations are working
  String get appTitle => translate('app_title');
  String get signIn => translate('sign_in');
  String get username => translate('username');
  String get password => translate('password');
  String get login => translate('login');
  String get profile => translate('profile');
  String get chat => translate('chat');
  String get exit => translate('exit');
  String get typeMessage => translate('type_message');
  String get send => translate('send');
  String get language => translate('language');
  String get english => translate('english');
  String get spanish => translate('spanish');
  String get signOut => translate('sign_out');
  String get googleSignIn => translate('google_sign_in');
  String get welcome => translate('welcome');
  String get readyToQuit => translate('ready_to_quit');
  String get betterHealth => translate('better_health');
  String get saveMoney => translate('save_money');
  String get moreEnergy => translate('more_energy');
  String get tellMeMore => translate('tell_me_more');
  String get welcomeQuitxt => translate('welcome_quitxt');
  String get messageBody => translate('message_body');
  String get benefits => translate('benefits');
  String get reasonToQuit => translate('reason_to_quit');
  String get yes => translate('yes');
  String get no => translate('no');
  String get user => translate('user');
  String get lastAccessTime => translate('last_access_time');
  String get signInMethod => translate('sign_in_method');
  String get userId => translate('user_id');
}

// Localization delegate
class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  
  @override
  bool isSupported(Locale locale) {
    return ['en', 'es'].contains(locale.languageCode);
  }
  
  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }
  
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}