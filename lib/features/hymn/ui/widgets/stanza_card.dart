import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/app_colors.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';

class StanzaCard extends StatelessWidget {
  final String text;
  final int displayIndex;
  final bool isChorus;

  const StanzaCard({
    super.key,
    required this.text,
    required this.displayIndex,
    this.isChorus = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine Colors
    Color cardBg;
    Color cardText;
    Color cardNumColor;

    if (isChorus) {
      // Chorus uses the brand primary color as the standout "main color"
      cardBg = isDark ? AppColors.primaryLight : AppColors.primary;
      cardText = AppColors.neutral100;
      cardNumColor = isDark
          ? AppColors.primaryDark
          : AppColors.primaryLight.withValues(alpha: 0.3);
    } else {
      // Other stanzas follow the "odd" styling as requested
      if (isDark) {
        cardBg = AppColors.neutral850;
        cardText = AppColors.neutral100;
        cardNumColor = AppColors.neutral700;
      } else {
        cardBg = AppColors.secondary50;
        cardText = AppColors.primaryDark;
        cardNumColor = AppColors.secondary100;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(32),
          border: isChorus
              ? Border.all(color: cardText.withValues(alpha: 0.2), width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Big Watermark Number/Label inside card
            Positioned(
              right: 0,
              top: -30,
              bottom: 0,
              child: Center(
                child: Text(
                  isChorus ? 'C' : '$displayIndex',
                  style: AppTextStyles.displayLarge.copyWith(
                    fontSize: isChorus ? 64 : 98,
                    height: .7,
                    color: cardNumColor,
                  ),
                ),
              ),
            ),
            // Text Content
            Padding(
              padding: const EdgeInsets.only(right: 40),
              child: Text(
                text,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cardText,
                  fontStyle: isChorus ? FontStyle.italic : null,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
