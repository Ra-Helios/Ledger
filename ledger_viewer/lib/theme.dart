// lib/theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // Colours matching the web app
  static const bg       = Color(0xFF0a0c10);
  static const surface  = Color(0xFF111318);
  static const surface2 = Color(0xFF181b22);
  static const surface3 = Color(0xFF1e2230);
  static const border   = Color(0xFF252a38);
  static const accent   = Color(0xFF3b82f6);
  static const green    = Color(0xFF10b981);
  static const red      = Color(0xFFef4444);
  static const yellow   = Color(0xFFf59e0b);
  static const purple   = Color(0xFF8b5cf6);
  static const cyan     = Color(0xFF06b6d4);
  static const pink     = Color(0xFFec4899);
  static const text     = Color(0xFFe2e8f0);
  static const text2    = Color(0xFF94a3b8);
  static const text3    = Color(0xFF475569);

  static const chartColors = [
    accent, purple, green, yellow, red, cyan, pink,
    Color(0xFF84cc16), Color(0xFFf97316),
  ];

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      surface: surface,
      onSurface: text,
      secondary: purple,
      error: red,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      foregroundColor: text,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: text,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    ),
    cardTheme: CardTheme(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: border),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(color: border, space: 0),
    textTheme: const TextTheme(
      bodyLarge:  TextStyle(color: text,  fontSize: 14),
      bodyMedium: TextStyle(color: text2, fontSize: 13),
      bodySmall:  TextStyle(color: text3, fontSize: 11),
      labelLarge: TextStyle(color: text,  fontSize: 12, fontWeight: FontWeight.w600),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: accent, width: 1.5),
      ),
      hintStyle: const TextStyle(color: text3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface2,
      labelStyle: const TextStyle(color: text2, fontSize: 11),
      side: const BorderSide(color: border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    ),
  );
}

// Mode badge color helper
Color modeColor(String mode) {
  switch (mode) {
    case 'Cash':         return AppTheme.green;
    case 'Gpay':         return AppTheme.accent;
    case 'UPI':          return AppTheme.yellow;
    case 'Cheque':       return AppTheme.pink;
    case 'Bank Transfer':return AppTheme.purple;
    default:             return AppTheme.text2;
  }
}

Color modeColorBg(String mode) => modeColor(mode).withOpacity(0.15);
