import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:openbaptisthymnal/core/theme/app_colors.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';

class HymnListTile extends StatelessWidget {
  final String number;
  final String title;
  final VoidCallback? onTap;
  final bool isFavorited;

  const HymnListTile({
    super.key,
    required this.number,
    required this.title,
    this.onTap,
    this.isFavorited = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Warm charcoal + gold in dark mode (no navy); the existing cream card in
    // light mode is already warm, so we only retune the dark palette here.
    final cardColor = isDark ? AppColors.neutral800 : AppColors.secondary100;
    // A hairline border gives each row a defined edge instead of letting the
    // cards melt into the cream canvas — the main "professional" lift.
    final cardBorder =
        isDark ? AppColors.neutral700 : AppColors.secondary200;
    // Number badge: a single gold-keyed squircle (was a white pill nested in a
    // cream pill, which read as visually noisy). Gold numerals are the brand.
    final badgeColor = isDark
        ? AppColors.secondary.withValues(alpha: 0.16)
        : AppColors.surfaceLight;
    final badgeBorder = AppColors.secondary.withValues(alpha: 0.32);
    const numberColor = AppColors.secondary;
    final titleColor = isDark ? AppColors.neutral100 : AppColors.primary;
    // Muted trailing chevron — a navigation affordance, not a focal point.
    final trailingColor = isDark ? AppColors.neutral500 : AppColors.primary300;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 64,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cardBorder, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Row(
              children: [
                // Hymn number badge — fixed square so 3- and 4-digit numbers
                // stay vertically aligned down the list.
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: badgeBorder, width: 1),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    number.padLeft(3, '0'),
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: numberColor,
                      letterSpacing: 0.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Hymn title
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Favorite indicator
                if (isFavorited) ...[
                  Icon(
                    PhosphorIcons.heart(PhosphorIconsStyle.fill),
                    size: 16,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 8),
                ],
                // Arrow icon
                Icon(
                  PhosphorIcons.caretRight(),
                  size: 22,
                  color: trailingColor,
                ),
                const SizedBox(width: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
