import 'package:flutter/material.dart';

class AppTheme {
  // QuitTXT Color Scheme
  static const Color quitxtPurple = Color(0xFF8100C0);   // Header bar color
  static const Color quitxtTeal = Color(0xFF009688);     // Chat bubbles, navigation drawer
  static const Color quitxtGreen = Color(0xFF90C418);    // Login background
  static const Color quitxtBlack = Color(0xFF000000);    // QuitTXT logo background
  static const Color quitxtWhite = Color(0xFFFFFFFF);    // Text and card background
  static const Color quitxtGray = Color(0xFF757575);     // Received messages
  
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: quitxtTeal,
      secondary: quitxtPurple,
      background: quitxtWhite,
      surface: quitxtWhite,
      error: Colors.red,
      onPrimary: quitxtWhite,
      onSecondary: quitxtWhite,
    ),
    scaffoldBackgroundColor: quitxtWhite,
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: quitxtPurple,
      foregroundColor: quitxtWhite,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: quitxtWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: quitxtTeal),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: quitxtTeal),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: quitxtTeal, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: quitxtWhite,
        backgroundColor: quitxtTeal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: quitxtTeal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: quitxtTeal,
      scrimColor: Colors.black54,
    ),
  );

  // Since the app appears to use light theme only, we'll keep dark theme similar but aligned
  static final ThemeData darkTheme = lightTheme;
}