import 'package:flutter/material.dart';

class Palette {
  // Brand
  static const Color accent = Color(0xFFD35400); // Terracotta/Tomato

  // Light Mode
  static const Color backgroundLight = Color(0xFFFAFAFA); // Off-white
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color textPrimaryLight = Color(0xFF111111);
  static const Color textSecondaryLight = Color(0xFF757575);

  // Dark Mode
  static const Color backgroundDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF1C1C1E);
  static const Color borderDark = Color(0xFF38383A);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark =
      Color(0x99EBEBF5); // iOS-like secondary dark
}
