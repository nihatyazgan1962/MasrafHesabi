import 'package:flutter/material.dart';

class AppTheme {
  // Canlı, modern koyu ve açık renk paleti
  static const primaryColor = Color(0xFF4F46E5); // Indigo 600
  static const primaryLight = Color(0xFF6366F1);
  static const accentGreen = Color(0xFF10B981); // Emerald
  static const accentRed = Color(0xFFEF4444); // Rose red
  static const accentOrange = Color(0xFFF59E0B); // Amber

  // Açık Tema
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: primaryColor,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Slate 50
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFF1E293B)),
      titleTextStyle: TextStyle(
        color: Color(0xFF1E293B),
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );

  // Koyu Tema
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: primaryLight,
    scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF1E293B),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
