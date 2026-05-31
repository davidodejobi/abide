import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/features/share_card/ui/share_card_style.dart';

/// The shareable scripture card: verse text as the hero, with its reference and
/// the Abide mark beneath. Fixed 4:5 portrait so exports stay consistent across
/// style presets. Mirrors [LyricCard] without the hymn-number watermark.
class ScriptureCard extends StatelessWidget {
  const ScriptureCard({
    super.key,
    required this.reference,
    required this.body,
    required this.style,
  });

  /// Full citation, e.g. `John 3:16–18`.
  final String reference;

  /// The selected verse text, already joined.
  final String body;

  final ShareCardStyle style;

  @override
  Widget build(BuildContext context) {
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
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Text(
                        body,
                        style: style.bodyStyle.copyWith(
                          color: style.ink,
                          fontSize: 24,
                          height: 1.55,
                        ),
                      ),
                    ),
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
