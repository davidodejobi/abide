import 'package:flutter/material.dart';

import 'app_colors.dart';

/// App typography and text styles
abstract final class AppTextStyles {
  // ============================================
  // FONT FAMILIES
  // ============================================

  /// Primary font family - used for most UI text
  static const String fontFamilyGeist = 'Geist';

  /// Display/Serif font family - used for headings and hymn content
  static const String fontFamilyEBGaramond = 'EBGaramond';

  /// Hand-printed marker font - used for the hand-drawn onboarding doodle screens
  static const String fontFamilyShantellSans = 'ShantellSans';

  /// Hand-printed fallback for the doodle styles
  static const String fontFamilyPatrickHand = 'PatrickHand';

  // ============================================
  // DISPLAY TEXT STYLES (EB Garamond - Serif)
  // ============================================

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamilyEBGaramond,
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamilyEBGaramond,
    fontSize: 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.16,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamilyEBGaramond,
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.22,
  );

  // ============================================
  // HEADLINE TEXT STYLES (EB Garamond - Serif)
  // ============================================

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamilyEBGaramond,
    fontSize: 32,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamilyEBGaramond,
    fontSize: 28,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.29,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamilyEBGaramond,
    fontSize: 24,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.33,
  );

  // ============================================
  // TITLE TEXT STYLES (Geist - Sans-serif)
  // ============================================

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamilyGeist,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.27,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamilyGeist,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.5,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamilyGeist,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // ============================================
  // BODY TEXT STYLES (Geist - Sans-serif)
  // ============================================

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamilyGeist,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamilyGeist,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamilyGeist,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // ============================================
  // LABEL TEXT STYLES (Geist - Sans-serif)
  // ============================================

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamilyGeist,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamilyGeist,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamilyGeist,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
  );

  // ============================================
  // HYMNAL SPECIFIC TEXT STYLES (EB Garamond)
  // ============================================

  /// Style for hymn number display
  static TextStyle hymnNumber({Color? color}) => TextStyle(
        fontFamily: fontFamilyEBGaramond,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.secondary,
        letterSpacing: 0.5,
      );

  /// Style for hymn title
  static TextStyle hymnTitle({Color? color}) => TextStyle(
        fontFamily: fontFamilyEBGaramond,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.primary,
        height: 1.4,
      );

  /// Style for hymn verse text
  static TextStyle hymnVerse({Color? color}) => TextStyle(
        fontFamily: fontFamilyEBGaramond,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.neutral900,
        height: 1.6,
        letterSpacing: 0.3,
      );

  /// Style for hymn chorus text
  static TextStyle hymnChorus({Color? color}) => TextStyle(
        fontFamily: fontFamilyEBGaramond,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
        color: color ?? AppColors.primary400,
        height: 1.6,
        letterSpacing: 0.3,
      );

  // ============================================
  // ONBOARDING — HAND-DRAWN DOODLE TEXT STYLES
  // ============================================
  // Pure hand-printed marker (Shantell Sans). Color defaults to null so the
  // onboarding screens pass colorScheme.onSurface — keeping it theme-aware
  // (dark ink on light, light ink on dark).

  /// Body line typed out on the hand-drawn onboarding screens
  static TextStyle doodleBody({Color? color}) => TextStyle(
        fontFamily: fontFamilyShantellSans,
        fontFamilyFallback: const [fontFamilyPatrickHand],
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.45,
        letterSpacing: 0.2,
      );

  /// Larger hand-drawn headline (e.g. a single prompt line)
  static TextStyle doodleHeadline({Color? color}) => TextStyle(
        fontFamily: fontFamilyShantellSans,
        fontFamilyFallback: const [fontFamilyPatrickHand],
        fontSize: 30,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.3,
        letterSpacing: 0.2,
      );

  /// Hand-drawn button label
  static TextStyle doodleButton({Color? color}) => TextStyle(
        fontFamily: fontFamilyShantellSans,
        fontFamilyFallback: const [fontFamilyPatrickHand],
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.0,
        letterSpacing: 0.5,
      );

  /// Small hand-drawn label / caption
  static TextStyle doodleLabel({Color? color}) => TextStyle(
        fontFamily: fontFamilyShantellSans,
        fontFamilyFallback: const [fontFamilyPatrickHand],
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.4,
      );
}
