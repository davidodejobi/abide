import 'package:flutter/material.dart';
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
    // Faint gold wash behind the number, gold numerals — replaces the old
    // light-blue number that read as "too much blue".
    final badgeColor = isDark
        ? AppColors.secondary.withValues(alpha: 0.14)
        : AppColors.surfaceLight;
    const numberColor = AppColors.secondary;
    final titleColor = isDark ? AppColors.neutral100 : AppColors.primary;
    final trailingColor = isDark ? AppColors.neutral500 : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(33),
          child: Ink(
            height: 65,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(33),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                // Hymn number badge
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      number.padLeft(3, '0'),
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: numberColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 22),
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
                if (isFavorited)
                  const Icon(
                    Icons.favorite,
                    size: 18,
                    color: AppColors.secondary,
                  ),
                // Arrow icon
                Icon(
                  Icons.chevron_right,
                  size: 24,
                  color: trailingColor,
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
