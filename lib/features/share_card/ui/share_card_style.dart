import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/app_colors.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';

/// A visual preset for a shareable lyric card: background, ink color, and the
/// text style family used for the lyric body.
class ShareCardStyle {
  const ShareCardStyle({
    required this.id,
    required this.label,
    required this.gradient,
    required this.ink,
    required this.accent,
    required this.bodyStyle,
  });

  final String id;
  final String label;
  final Gradient gradient;

  /// Primary text color (title + lyrics).
  final Color ink;

  /// Secondary color used for the hymn number watermark and footer.
  final Color accent;

  /// Base style for the lyric body; color is applied from [ink] at render time.
  final TextStyle bodyStyle;

  static final List<ShareCardStyle> presets = [
    ShareCardStyle(
      id: 'navy',
      label: 'Midnight',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.primaryDark],
      ),
      ink: AppColors.neutral100,
      accent: AppColors.secondaryLight,
      bodyStyle: AppTextStyles.hymnVerse(),
    ),
    ShareCardStyle(
      id: 'cream',
      label: 'Parchment',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.secondary50, AppColors.secondary100],
      ),
      ink: AppColors.primaryDark,
      accent: AppColors.secondary,
      bodyStyle: AppTextStyles.hymnVerse(),
    ),
    ShareCardStyle(
      id: 'gold',
      label: 'Gold',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.secondary, AppColors.secondaryDark],
      ),
      ink: AppColors.neutral100,
      accent: AppColors.secondary200,
      bodyStyle: AppTextStyles.hymnVerse(),
    ),
    ShareCardStyle(
      id: 'ink',
      label: 'Ink',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.neutral850, AppColors.neutral900],
      ),
      ink: AppColors.neutral100,
      accent: AppColors.primary400,
      bodyStyle: AppTextStyles.hymnVerse(),
    ),
  ];
}
