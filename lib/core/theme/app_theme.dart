import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // Cinematic Precision Colors — brand color, identical in both modes.
  static const Color _actionOrange = Color(0xFFFF571A);
  static const Color _onAction = Color(0xFF1A1A1A);

  // Dark palette (unchanged from the original dark-only theme).
  static const Color _darkBg = Color(0xFF131313);
  static const Color _darkSurface = Color(0xFF1C1B1B);
  static const Color _darkBorder = Color(0xFF393939);
  static const Color _darkOnSurface = Colors.white;

  // Light palette.
  static const Color _lightBg = Color(0xFFF4F4F4);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightBorder = Color(0xFFDBDBDB);
  static const Color _lightOnSurface = Color(0xFF1A1A1A);

  static ThemeData get darkTheme => _build(
        brightness: Brightness.dark,
        scaffoldBg: _darkBg,
        surface: _darkSurface,
        border: _darkBorder,
        onSurface: _darkOnSurface,
        appColors: AppColors.dark,
      );

  static ThemeData get lightTheme => _build(
        brightness: Brightness.light,
        scaffoldBg: _lightBg,
        surface: _lightSurface,
        border: _lightBorder,
        onSurface: _lightOnSurface,
        appColors: AppColors.light,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color scaffoldBg,
    required Color surface,
    required Color border,
    required Color onSurface,
    required AppColors appColors,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: _actionOrange,
      onPrimary: _onAction,
      secondary: _actionOrange,
      onSecondary: _onAction,
      error: appColors.danger,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      outline: border,
      surfaceContainerHighest: appColors.surfaceElevated,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      extensions: [appColors],
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 56,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: _actionOrange,
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'HankenGrotesk',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _actionOrange, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        labelStyle: TextStyle(
          fontFamily: 'HankenGrotesk',
          fontSize: 12,
          color: appColors.textFaint,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _actionOrange,
        foregroundColor: _onAction,
        elevation: 2,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'HankenGrotesk',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: onSurface,
        ),
        titleMedium: TextStyle(
          fontFamily: 'HankenGrotesk',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'HankenGrotesk',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: appColors.textMuted,
        ),
        labelSmall: TextStyle(
          fontFamily: 'HankenGrotesk',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: appColors.textFaint,
        ),
      ),
    );
  }
}
