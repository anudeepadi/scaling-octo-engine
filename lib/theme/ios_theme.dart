
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class IosTheme {
  // Colors
  static const Color primaryColor = CupertinoColors.activeBlue;
  static const Color backgroundColor = CupertinoColors.systemBackground;
  static const Color secondaryColor = CupertinoColors.secondarySystemBackground;
  static const Color textColor = CupertinoColors.label;
  static const Color hintColor = CupertinoColors.placeholderText;
  static const Color accentColor = CupertinoColors.activeOrange;
  
  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: secondaryColor,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textColor),
        bodyMedium: TextStyle(color: textColor),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      iconTheme: const IconThemeData(
        color: primaryColor,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: secondaryColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        surface: backgroundColor,
      ),
    );
  }
  
  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: CupertinoColors.darkBackgroundGray,
      cardColor: CupertinoColors.systemGrey6.darkColor,
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: CupertinoColors.label.darkColor),
        bodyMedium: TextStyle(color: CupertinoColors.label.darkColor),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: CupertinoColors.darkBackgroundGray,
        foregroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      iconTheme: const IconThemeData(
        color: primaryColor,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: CupertinoColors.systemGrey6.darkColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        surface: CupertinoColors.darkBackgroundGray,
        brightness: Brightness.dark,
      ),
    );
  }
}
