// ============================================================
// FIKAGO - THEME
// ============================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FikaGoColors {
  static const Color forestGreen = Color(0xFF0B6B3A);
  static const Color sunYellow = Color(0xFFFFC107);
  static const Color lightGreen = Color(0xFFE8F5EC);
  static const Color charcoal = Color(0xFF1F1F1F);
  static const Color lightGrey = Color(0xFFF4F6F5);
  static const Color grey = Color(0xFF707873);
  static const Color green = Color(0xFF0B6B3A);
  static const Color red = Color(0xFFC62828);
  static const Color white = Colors.white;
}

class FikaGoTheme {
  static ThemeData lightTheme = ThemeData(
    primaryColor: FikaGoColors.forestGreen,
    scaffoldBackgroundColor: FikaGoColors.lightGreen,
    colorScheme: const ColorScheme.light(
      primary: FikaGoColors.forestGreen,
      onPrimary: FikaGoColors.lightGreen,
      primaryContainer: FikaGoColors.lightGreen,
      onPrimaryContainer: FikaGoColors.charcoal,
      secondary: FikaGoColors.sunYellow,
      onSecondary: FikaGoColors.charcoal,
      secondaryContainer: FikaGoColors.sunYellow,
      onSecondaryContainer: FikaGoColors.charcoal,
      tertiary: FikaGoColors.forestGreen,
      onTertiary: FikaGoColors.lightGreen,
      error: FikaGoColors.charcoal,
      onError: FikaGoColors.lightGreen,
      errorContainer: FikaGoColors.lightGreen,
      onErrorContainer: FikaGoColors.charcoal,
      surface: FikaGoColors.lightGreen,
      onSurface: FikaGoColors.charcoal,
      surfaceContainerLowest: FikaGoColors.lightGreen,
      surfaceContainerLow: FikaGoColors.lightGreen,
      surfaceContainer: FikaGoColors.lightGreen,
      surfaceContainerHigh: FikaGoColors.lightGreen,
      surfaceContainerHighest: FikaGoColors.lightGreen,
      onSurfaceVariant: FikaGoColors.charcoal,
      outline: FikaGoColors.charcoal,
      outlineVariant: FikaGoColors.charcoal,
      shadow: FikaGoColors.charcoal,
      scrim: FikaGoColors.charcoal,
      inverseSurface: FikaGoColors.charcoal,
      onInverseSurface: FikaGoColors.lightGreen,
      inversePrimary: FikaGoColors.lightGreen,
      surfaceTint: FikaGoColors.forestGreen,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: FikaGoColors.forestGreen,
      foregroundColor: FikaGoColors.lightGreen,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: FikaGoColors.lightGreen,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: FikaGoColors.sunYellow,
        foregroundColor: FikaGoColors.charcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    textTheme: GoogleFonts.montserratTextTheme().apply(
      bodyColor: FikaGoColors.charcoal,
      displayColor: FikaGoColors.charcoal,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: FikaGoColors.lightGreen,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}
