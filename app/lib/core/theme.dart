import 'package:flutter/material.dart';

class AppTheme {
  static const ink = Color(0xFFEDEBE4);
  static const muted = Color(0xFF9BA39D);
  static const surface = Color(0xFF171B1B);
  static const panel = Color(0xFF202626);
  static const green = Color(0xFF8DD5A5);
  static const gold = Color(0xFFE6B86A);
  static const red = Color(0xFFF18A83);

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: gold,
      brightness: Brightness.dark,
      surface: surface,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        surface: surface,
        onSurface: ink,
        primary: gold,
        secondary: green,
        error: red,
      ),
      scaffoldBackgroundColor: surface,
      cardTheme: const CardTheme(
        color: panel,
        margin: EdgeInsets.zero,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: panel,
        indicatorColor: gold.withOpacity(.18),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}