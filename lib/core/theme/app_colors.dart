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

  /// Near black - Background dark mode
  static const Color neutral900 = Color(0xFF0C0C0C);

  /// Dark gray - Surface dark mode
  static const Color neutral850 = Color(0xFF141414);

  /// Dark gray - Surface container dark
  static const Color neutral800 = Color(0xFF1A1A1A);

  /// Medium dark gray - Verse numbers background
  static const Color neutral700 = Color(0xFF2B2B2B);

  /// Icon inactive
  static const Color neutral600 = Color(0xFF626262);

  /// Medium gray
  static const Color neutral500 = Color(0xFF848484);

  /// Light gray
  static const Color neutral400 = Color(0xFFA1A1AA);

  /// Light gray
  static const Color neutral300 = Color(0xFFBFBFBF);

  /// Beige / Divider light
  static const Color neutral200 = Color(0xFFD8D5CC);

  /// Off-white / Cream - Primary text on dark
  static const Color neutral100 = Color(0xFFFAF8F3);

  // ============================================
  // SEMANTIC COLORS
  // ============================================

  /// White
  static const Color white = Color(0xFFFFFFFF);

  /// Black
  static const Color black = Color(0xFF000000);

  /// Black shade 950 (near black)
  static const Color black950 = Color(0xFF0A0A0A);

  /// Black shade 500 (medium dark)
  static const Color black500 = Color(0xFF737373);

  /// Black shade 400
  static const Color black400 = Color(0xFF9CA3AF);

  /// Background color (Light mode)
  static const Color backgroundLight = neutral100;

  /// Background color (Dark mode) - #0C0C0C
  static const Color backgroundDark = neutral900;

  /// Surface color (Light mode)
  static const Color surfaceLight = white;

  /// Surface color (Dark mode) - #141414
  static const Color surfaceDark = neutral850;

  /// Surface container (Dark mode) - #1A1A1A
  static const Color surfaceContainerDark = neutral800;

  /// Error color
  static const Color error = Color(0xFFB00020);

  /// Success color
  static const Color success = Color(0xFF4CAF50);

  /// Warning color
  static const Color warning = Color(0xFFFFC107);

  /// Info color
  static const Color info = Color(0xFF2196F3);
}
