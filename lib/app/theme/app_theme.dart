import 'package:flutter/material.dart';

class AppThemePalette {
  const AppThemePalette._();

  static const Color lightPrimary = Color(0xFF1152D4);
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1E293B);
  static const Color lightTextMuted = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFCBD5E1);
  static const Color lightSuccess = Color(0xFF16A34A);
  static const Color lightError = Color(0xFFDC2626);

  static const Color darkPrimary = Color(0xFF9333EA);
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkTextMuted = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkSuccess = Color(0xFF22C55E);
  static const Color darkError = Color(0xFFF87171);
}

class AppTheme {
  static ThemeData get light {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppThemePalette.lightPrimary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppThemePalette.lightPrimary,
      onPrimary: Colors.white,
      secondary: AppThemePalette.lightSuccess,
      onSecondary: Colors.white,
      error: AppThemePalette.lightError,
      onError: Colors.white,
      surface: AppThemePalette.lightSurface,
      onSurface: AppThemePalette.lightText,
      onSurfaceVariant: AppThemePalette.lightTextMuted,
      outline: AppThemePalette.lightBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppThemePalette.lightBackground,
      canvasColor: AppThemePalette.lightBackground,
      dividerColor: AppThemePalette.lightBorder,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppThemePalette.lightSurface,
        foregroundColor: AppThemePalette.lightText,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppThemePalette.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppThemePalette.lightBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppThemePalette.lightSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: const TextStyle(color: AppThemePalette.lightTextMuted),
        labelStyle: const TextStyle(color: AppThemePalette.lightTextMuted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppThemePalette.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppThemePalette.lightPrimary,
            width: 1.4,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: const BorderSide(color: AppThemePalette.lightBorder),
        backgroundColor: const Color(0xFFF1F5F9),
        selectedColor: const Color(0xFFDBEAFE),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppThemePalette.lightText,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppThemePalette.lightPrimary,
        foregroundColor: Colors.white,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppThemePalette.lightText,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  static ThemeData get dark {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppThemePalette.darkPrimary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppThemePalette.darkPrimary,
      onPrimary: Colors.white,
      secondary: AppThemePalette.darkSuccess,
      onSecondary: const Color(0xFF052E16),
      error: AppThemePalette.darkError,
      onError: const Color(0xFF450A0A),
      surface: AppThemePalette.darkSurface,
      onSurface: AppThemePalette.darkText,
      onSurfaceVariant: AppThemePalette.darkTextMuted,
      outline: AppThemePalette.darkBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppThemePalette.darkBackground,
      canvasColor: AppThemePalette.darkBackground,
      dividerColor: AppThemePalette.darkBorder,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppThemePalette.darkBackground,
        foregroundColor: AppThemePalette.darkText,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppThemePalette.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppThemePalette.darkBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppThemePalette.darkSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: const TextStyle(color: AppThemePalette.darkTextMuted),
        labelStyle: const TextStyle(color: AppThemePalette.darkTextMuted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppThemePalette.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppThemePalette.darkPrimary,
            width: 1.4,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: const BorderSide(color: AppThemePalette.darkBorder),
        backgroundColor: const Color(0xFF1A2437),
        selectedColor: const Color(0xFF3B1B67),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppThemePalette.darkText,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppThemePalette.darkPrimary,
        foregroundColor: Colors.white,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF111827),
        contentTextStyle: const TextStyle(color: AppThemePalette.darkText),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
