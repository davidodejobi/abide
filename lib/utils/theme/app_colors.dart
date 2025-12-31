import 'package:flutter/material.dart';

/// App color palette extracted from Figma design
/// https://www.figma.com/design/Kig869DTVVbNvQZG65OdeO/MC?node-id=388-7432
abstract final class AppColors {
  // ============================================
  // PRIMARY COLORS (Navy Blue)
  // ============================================

  /// Primary color - Navy Blue
  static const Color primary = Color(0xFF1C2A4A);

  /// Primary dark variant
  static const Color primaryDark = Color(0xFF11192C);

  /// Primary light variant
  static const Color primaryLight = Color(0xFF394768);

  /// Primary shade 400
  static const Color primary400 = Color(0xFF7482A4);

  /// Primary shade 300
  static const Color primary300 = Color(0xFF91A0C2);

  /// Primary shade 200
  static const Color primary200 = Color(0xFFAEBDE0);

  // ============================================
  // SECONDARY/ACCENT COLORS (Gold)
  // ============================================

  /// Secondary/Accent color - Gold
  static const Color secondary = Color(0xFFC9A24D);

  /// Secondary dark variant
  static const Color secondaryDark = Color(0xFF50411F);

  /// Secondary light variant
  static const Color secondaryLight = Color(0xFFD4B571);

  /// Secondary shade 200
  static const Color secondary200 = Color(0xFFE9DAB8);

  /// Secondary shade 100
  static const Color secondary100 = Color(0xFFF4ECDB);

  /// Secondary shade 50
  static const Color secondary50 = Color(0xFFFAF6ED);

  // ============================================
  // NEUTRAL COLORS (Grayscale)
  // ============================================

  /// Near black
  static const Color neutral900 = Color(0xFF1A1A1A);

  /// Dark gray
  static const Color neutral800 = Color(0xFF2B2B2B);

  /// Medium gray
  static const Color neutral500 = Color(0xFF848484);

  /// Light gray
  static const Color neutral300 = Color(0xFFBFBFBF);

  /// Off-white / Cream
  static const Color neutral100 = Color(0xFFFAF8F3);

  /// Beige
  static const Color neutral200 = Color(0xFFD8D5CC);

  // ============================================
  // SEMANTIC COLORS
  // ============================================

  /// White
  static const Color white = Color(0xFFFFFFFF);

  /// Black
  static const Color black = Color(0xFF000000);

  /// Background color (Light mode)
  static const Color backgroundLight = neutral100;

  /// Background color (Dark mode)
  static const Color backgroundDark = neutral900;

  /// Surface color (Light mode)
  static const Color surfaceLight = white;

  /// Surface color (Dark mode)
  static const Color surfaceDark = neutral800;

  /// Error color
  static const Color error = Color(0xFFB00020);

  /// Success color
  static const Color success = Color(0xFF4CAF50);

  /// Warning color
  static const Color warning = Color(0xFFFFC107);

  /// Info color
  static const Color info = Color(0xFF2196F3);
}
