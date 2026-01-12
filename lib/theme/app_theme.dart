import 'package:flutter/material.dart';

class AppTheme {
  // ----- Colors -----
  static const Color primary = Colors.orange;
  static const Color primary400 = Color.fromARGB(255, 244, 184, 93);
  static const Color primary600 = Color.fromARGB(255, 255, 152, 0);
  static const Color background = Color(0xFFF8F8F8);
  static const Color card = Colors.white;
  static const Color textPrimary = Color(0xFF1E1E1E);
  static const Color textSecondary = Color(0xFF8A8A8A);
  static const Color confirmation = Color.fromARGB(255, 63, 134, 89);
  static const Color error = Color.fromARGB(255, 255, 0, 25);
  static const Color accent = Color(0xFFFFA07A);
  static const Color secondary = Color.fromARGB(255, 168, 154, 154);

  // ----- Light Theme -----
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: background,
    primaryColor: primary,
    secondaryHeaderColor: textPrimary,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
      bodyMedium: TextStyle(color: textPrimary),
      bodySmall: TextStyle(color: textSecondary),
    ),
    iconTheme: const IconThemeData(color: primary),
  );

  // ----- Dark Theme -----
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    primaryColor: primary,
    secondaryHeaderColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    cardColor: const Color(0xFF1E1E1E),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary600,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Colors.grey),
    ),
    iconTheme: const IconThemeData(color: primary),
  );
}
