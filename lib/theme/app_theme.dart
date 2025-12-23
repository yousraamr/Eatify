import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFFFF6B57);
  static const Color background = Color(0xFFF8F8F8);
  static const Color card = Colors.white;
  static const Color textPrimary = Color(0xFF1E1E1E);
  static const Color textSecondary = Color(0xFF8A8A8A);

  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: background,
    primaryColor: primary,

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
    ),

    cardColor: card,

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),

    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      bodyMedium: TextStyle(
        color: textPrimary,
      ),
      bodySmall: TextStyle(
        color: textSecondary,
      ),
    ),

    iconTheme: const IconThemeData(
      color: primary,
    ),
  );
}
