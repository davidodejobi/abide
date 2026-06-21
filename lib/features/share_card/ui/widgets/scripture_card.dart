import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/features/share_card/ui/scripture_share_card_page.dart'
    show ShareVerse;
import 'package:openbaptisthymnal/features/share_card/ui/share_card_style.dart';

/// The shareable scripture card: verse text as the hero, with its reference and
/// the Abide mark beneath. Fixed 4:5 portrait so exports stay consistent across
/// style presets. Mirrors [LyricCard] without the hymn-number watermark.
///
/// Each verse is prefixed with its number so the boundaries between verses stay
/// visible, and the text fills the card from the top-left, scaling down only
/// when a long passage would otherwise overflow.
class ScriptureCard extends StatelessWidget {
  const ScriptureCard({
    super.key,
    required this.reference,
    required this.verses,
    required this.style,
  });

  /// Full citation, e.g. `John 3:16–18`.
  final String reference;

  /// The selected verses in reading order.
  final List<ShareVerse> verses;

  final ShareCardStyle style;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = style.bodyStyle.copyWith(
      color: style.ink,
      fontSize: 24,
      height: 1.55,
    );
    final numberStyle = bodyStyle.copyWith(
      fontSize: 15,
      color: style.accent,
      fontWeight: FontWeight.w700,
    );

    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        decoration: BoxDecoration(gradient: style.gradient),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: AutoSizeText.rich(
                    TextSpan(
                      children: [
                        for (var i = 0; i < verses.length; i++) ...[
                          if (i > 0) const TextSpan(text: '  '),
                          TextSpan(
                            text: '${verses[i].number} ',
                            style: numberStyle,
                          ),
                          TextSpan(text: verses[i].text),
                        ],
                      ],
                    ),
                    style: bodyStyle,
                    // Shrinks the FONT size to fit (not the layout), so the
                    // text always fills the full card width — no more text
                    // hugging the left edge with empty space on the right.
                    minFontSize: 12,
                    maxFontSize: 24,
                    stepGranularity: 0.5,
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                reference,
                style: AppTextStyles.titleMedium.copyWith(
                  color: style.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(width: 28, height: 2, color: style.accent),
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
      ),
    );
  }
}
