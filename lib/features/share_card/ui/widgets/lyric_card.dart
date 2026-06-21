import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/features/share_card/ui/share_card_style.dart';

/// The visual lyric card that gets captured and shared as an image.
///
/// Sized to a fixed 4:5 portrait ratio so the exported PNG looks consistent
/// across the different style presets.
class LyricCard extends StatelessWidget {
  const LyricCard({
    super.key,
    required this.hymnNumber,
    required this.title,
    required this.body,
    required this.style,
  });

  final String hymnNumber;
  final String title;
  final String body;
  final ShareCardStyle style;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        decoration: BoxDecoration(gradient: style.gradient),
        child: Stack(
          children: [
            // Large hymn-number watermark.
            Positioned(
              top: -24,
              right: 12,
              child: Text(
                hymnNumber,
                style: AppTextStyles.displayLarge.copyWith(
                  fontSize: 160,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: style.accent.withValues(alpha: 0.18),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: style.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SizedBox(
                      width: double.infinity,
                      child: AutoSizeText(
                        body,
                        style: style.bodyStyle.copyWith(
                          color: style.ink,
                          fontSize: 22,
                          height: 1.55,
                        ),
                        // Shrinks the FONT to fit, not the layout — so long
                        // lyrics fill the full card width instead of hugging
                        // the left edge.
                        minFontSize: 12,
                        maxFontSize: 22,
                        stepGranularity: 0.5,
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 2,
                        color: style.accent,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Abide',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: style.accent,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
