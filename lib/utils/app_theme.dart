import 'package:flutter/material.dart';
import 'palette.dart';

class AppTheme {
  // Typography base configuration (System Fonts)
  static TextTheme _buildTextTheme(Color primaryColor, Color secondaryColor) {
    return TextTheme(
      displayLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          color: primaryColor,
          letterSpacing: -0.8,
          height: 1.2),
      displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: primaryColor,
          letterSpacing: -0.6,
          height: 1.2),
      titleLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: primaryColor,
          letterSpacing: -0.4,
          height: 1.3),
      titleMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryColor,
          letterSpacing: -0.3,
          height: 1.3),
      bodyLarge: TextStyle(
          fontSize: 16,
          color: primaryColor,
          height: 1.6,
          fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(
          fontSize: 14,
          color: secondaryColor,
          height: 1.5,
          fontWeight: FontWeight.w400),
      labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: primaryColor,
          letterSpacing: 0),
      labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: secondaryColor,
          letterSpacing: 0.2),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Palette.backgroundLight,
      primaryColor: Palette.accent,
      fontFamily:
          '.SF Pro Display', // Fallbacks handled by Flutter natively to Roboto on Android
      fontFamilyFallback: const [
        'Roboto',
        'Helvetica Neue',
        'Arial',
        'sans-serif'
      ],

      colorScheme: const ColorScheme.light(
        primary: Palette.accent,
        secondary: Palette.accent,
        surface: Palette.surfaceLight,
        onSurface: Palette.textPrimaryLight,
        outline: Palette.borderLight,
      ),

      textTheme:
          _buildTextTheme(Palette.textPrimaryLight, Palette.textSecondaryLight),

      cardTheme: CardTheme(
        color: Palette.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Palette.borderLight, width: 1),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: Palette.borderLight,
        thickness: 1,
        space: 1,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Palette.surfaceLight,
        modalBackgroundColor: Palette.surfaceLight,
        elevation: 8, // Minimal elevation for readability
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Palette.backgroundLight,
        elevation: 0, // No shadow by default
        scrolledUnderElevation: 4, // Slight shadow when scrolled under
        iconTheme: IconThemeData(color: Palette.textPrimaryLight),
        titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Palette.textPrimaryLight,
            letterSpacing: -0.3),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Palette.backgroundDark,
      primaryColor: Palette.accent,
      fontFamily: '.SF Pro Display',
      fontFamilyFallback: const [
        'Roboto',
        'Helvetica Neue',
        'Arial',
        'sans-serif'
      ],
      colorScheme: const ColorScheme.dark(
        primary: Palette.accent,
        secondary: Palette.accent,
        surface: Palette.surfaceDark,
        onSurface: Palette.textPrimaryDark,
        outline: Palette.borderDark,
      ),
      textTheme:
          _buildTextTheme(Palette.textPrimaryDark, Palette.textSecondaryDark),
      cardTheme: CardTheme(
        color: Palette.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Palette.borderDark, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Palette.borderDark,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Palette.surfaceDark,
        modalBackgroundColor: Palette.surfaceDark,
        elevation: 8,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Palette.backgroundDark,
        elevation: 0,
        scrolledUnderElevation: 4,
        iconTheme: IconThemeData(color: Palette.textPrimaryDark),
        titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Palette.textPrimaryDark,
            letterSpacing: -0.3),
      ),
    );
  }
}
