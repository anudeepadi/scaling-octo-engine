import 'package:flutter/material.dart';

class AppTheme {
  // Modern Health-Focused Color Palette
  // Primary Colors (2 main colors)
  static const Color primaryBlue = Color(0xFF6366F1);      // Modern indigo for primary actions
  static const Color wellnessGreen = Color(0xFF10B981);    // Calming green for health/success
  
  // Neutral Palette
  static const Color backgroundPrimary = Color(0xFFFAFBFC); // Warm white background
  static const Color backgroundSecondary = Color(0xFFF8FAFC); // Slightly cooler background
  static const Color surfaceWhite = Color(0xFFFFFFFF);     // Pure white for cards/surfaces
  static const Color surfaceGray = Color(0xFFF1F5F9);      // Light gray surfaces
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B);      // Dark slate for primary text
  static const Color textSecondary = Color(0xFF64748B);    // Medium slate for secondary text
  static const Color textTertiary = Color(0xFF94A3B8);     // Light slate for hints/placeholders
  
  // Accent Colors
  static const Color accentSoft = Color(0xFFEEF2FF);       // Very light indigo background
  static const Color accentGentle = Color(0xFFECFDF5);     // Very light green background
  static const Color borderLight = Color(0xFFE2E8F0);      // Light borders and dividers
  static const Color shadowSubtle = Color(0x08000000);     // Very subtle shadows
  
  // Status Colors
  static const Color errorSoft = Color(0xFFEF4444);        // Gentle red for errors
  static const Color errorRed = Color(0xFFDC2626);         // Stronger red for critical actions
  static const Color warningSoft = Color(0xFFF59E0B);      // Gentle amber for warnings
  static const Color warningOrange = Color(0xFFF97316);    // Stronger orange for warnings
  static const Color successSoft = Color(0xFF10B981);      // Same as wellness green
  static const Color accentPurple = Color(0xFF8B5CF6);     // Purple accent for motivation
  
  // Modern Gradients
  static const List<Color> primaryGradient = [
    Color(0xFF6366F1), // primaryBlue
    Color(0xFF8B5CF6), // Soft purple
  ];
  
  static const List<Color> wellnessGradient = [
    Color(0xFF10B981), // wellnessGreen
    Color(0xFF059669), // Darker green
  ];
  
  static const List<Color> glassmorphismGradient = [
    Color(0x20FFFFFF),
    Color(0x10FFFFFF),
  ];
  
  // Legacy color mappings for gradual migration
  static const Color quitxtPurple = primaryBlue;
  static const Color quitxtTeal = wellnessGreen;
  static const Color quitxtGreen = accentGentle;
  static const Color quitxtBlack = textPrimary;
  static const Color quitxtWhite = surfaceWhite;
  static const Color quitxtGray = textSecondary;
  
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'SF Pro Display', // Modern system font
    colorScheme: ColorScheme.light(
      primary: primaryBlue,
      secondary: wellnessGreen,
      surface: surfaceWhite,
      error: errorSoft,
      onPrimary: surfaceWhite,
      onSecondary: surfaceWhite,
      onSurface: textPrimary,
    ),
    scaffoldBackgroundColor: backgroundPrimary,
    
    // Modern card design with subtle elevation
    cardTheme: CardTheme(
      elevation: 0,
      shadowColor: shadowSubtle,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: surfaceWhite,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    
    // Clean app bar design
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: textPrimary,
      titleTextStyle: const TextStyle(
        color: textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      iconTheme: const IconThemeData(
        color: textPrimary,
        size: 24,
      ),
    ),
    
    // Modern input field styling
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderLight, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderLight, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorSoft, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(
        color: textTertiary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      labelStyle: const TextStyle(
        color: textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
    
    // Modern elevated button styling
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shadowColor: shadowSubtle,
        foregroundColor: surfaceWhite,
        backgroundColor: primaryBlue,
        disabledBackgroundColor: surfaceGray,
        disabledForegroundColor: textTertiary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    
    // Clean text button styling
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.25,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    
    // Clean drawer design
    drawerTheme: DrawerThemeData(
      backgroundColor: surfaceWhite,
      elevation: 0,
      shadowColor: shadowSubtle,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
    ),
    
    // Modern divider styling
    dividerTheme: const DividerThemeData(
      color: borderLight,
      thickness: 1,
      space: 1,
    ),
    
    // Clean bottom sheet design
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
    ),
  );

  // Since the app appears to use light theme only, we'll keep dark theme similar but aligned
  static final ThemeData darkTheme = lightTheme;
}