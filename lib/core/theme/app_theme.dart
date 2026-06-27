import 'package:flutter/material.dart';

class AppTheme {
  // Cinematic Precision Colors
  static const Color _darkBg = Color(0xFF131313);
  static const Color _surface = Color(0xFF1C1B1B);
  static const Color _border = Color(0xFF393939);
  static const Color _actionOrange = Color(0xFFFF571A);

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: _actionOrange,
          surface: _surface,
        ),
        scaffoldBackgroundColor: _darkBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: _darkBg,
          elevation: 0,
          centerTitle: false,
          toolbarHeight: 56,
        ),
        cardTheme: CardThemeData(
          color: _surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: _border, width: 1),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: _surface,
          selectedColor: _actionOrange,
          side: const BorderSide(color: _border),
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
          fillColor: _surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _actionOrange, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          labelStyle: const TextStyle(
            fontFamily: 'HankenGrotesk',
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _actionOrange,
          elevation: 2,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titleMedium: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white70,
          ),
          labelSmall: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
      );

  static ThemeData get lightTheme => darkTheme;
}
