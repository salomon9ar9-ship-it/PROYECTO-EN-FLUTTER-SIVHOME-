// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue   = Color(0xFF0D7BF5);
  static const Color primaryGreen  = Color(0xFF00C896);
  static const Color warningAmber  = Color(0xFFFFA500);
  static const Color dangerRed     = Color(0xFFFF3B3B);
  static const Color bgDark        = Color(0xFF0A0E1A);
  static const Color bgCard        = Color(0xFF111827);
  static const Color bgCardLight   = Color(0xFF1A2235);
  static const Color textPrimary   = Color(0xFFF0F4FF);
  static const Color textSecondary = Color(0xFF8A9BBE);
  static const Color electricColor = Color(0xFFFFD60A);
  static const Color waterColor    = Color(0xFF00B4FF);
  static const Color gasColor      = Color(0xFFFF6B35);

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: primaryBlue,
          secondary: primaryGreen,
          error: dangerRed,
          surface: bgCard,
        ),
        scaffoldBackgroundColor: bgDark,
        cardColor: bgCard,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: bgDark,
          foregroundColor: textPrimary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700,
            color: textPrimary, letterSpacing: 0.3,
          ),
        ),
        // ✅ CORREGIDO: CardThemeData en lugar de CardTheme
        cardTheme: CardThemeData(
          color: bgCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.06)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: bgCardLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryBlue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: dangerRed),
          ),
          labelStyle: const TextStyle(color: textSecondary),
          hintStyle: const TextStyle(color: textSecondary),
          prefixIconColor: textSecondary,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        textTheme: const TextTheme(
          displayLarge:  TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 32),
          displayMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 26),
          titleLarge:    TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 20),
          titleMedium:   TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
          bodyLarge:     TextStyle(color: textPrimary, fontSize: 16),
          bodyMedium:    TextStyle(color: textSecondary, fontSize: 14),
          labelLarge:    TextStyle(color: textPrimary, fontWeight: FontWeight.w500, fontSize: 14),
        ),
        dividerColor: Colors.white12,
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? Colors.white : textSecondary),
          trackColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? primaryBlue : Colors.white24),
        ),
      );
}