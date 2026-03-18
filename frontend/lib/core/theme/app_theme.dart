import 'package:flutter/material.dart';

class AppColors {
  // Primary palette
  static const primary      = Color(0xFF6C63FF);  // Purple
  static const primaryLight = Color(0xFF9D97FF);
  static const primaryDark  = Color(0xFF4A42D6);

  // Background
  static const bgDark       = Color(0xFF0F0F1A);
  static const bgCard       = Color(0xFF1A1A2E);
  static const bgCardLight  = Color(0xFF252540);

  // Text
  static const textPrimary  = Color(0xFFFFFFFF);
  static const textSecondary= Color(0xFFB0B0CC);
  static const textHint     = Color(0xFF6B6B8A);

  // Accents
  static const success      = Color(0xFF4CAF50);
  static const warning      = Color(0xFFFF9800);
  static const error        = Color(0xFFEF5350);
  static const info         = Color(0xFF29B6F6);

  // Chat bubbles
  static const userBubble   = Color(0xFF6C63FF);
  static const botBubble    = Color(0xFF1E1E35);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,

      colorScheme: const ColorScheme.dark(
        primary:   AppColors.primary,
        secondary: AppColors.primaryLight,
        surface:   AppColors.bgCard,
        error:     AppColors.error,
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor:  AppColors.bgDark,
        elevation:        0,
        centerTitle:      true,
        titleTextStyle: TextStyle(
          color:      AppColors.textPrimary,
          fontSize:   18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),

      // Cards
      cardTheme: CardThemeData(
        color:        AppColors.bgCard,
        elevation:    0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.bgCardLight, width: 1),
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled:      true,
        fillColor:   AppColors.bgCard,
        hintStyle:   const TextStyle(color: AppColors.textHint),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.bgCardLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.bgCardLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),

      // Text
      textTheme: const TextTheme(
        displayLarge:  TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        headlineMedium:TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        titleLarge:    TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        titleMedium:   TextStyle(color: AppColors.textPrimary),
        bodyLarge:     TextStyle(color: AppColors.textPrimary),
        bodyMedium:    TextStyle(color: AppColors.textSecondary),
        bodySmall:     TextStyle(color: AppColors.textHint),
      ),
    );
  }
}
