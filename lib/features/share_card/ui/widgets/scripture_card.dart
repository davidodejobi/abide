import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/features/share_card/ui/scripture_share_card_page.dart'
    show ShareVerse;
import 'package:openbaptisthymnal/features/share_card/ui/share_card_style.dart';
import 'package:openbaptisthymnal/features/share_card/ui/widgets/share_card_frame.dart';

/// The scripture card: the reference as the eyebrow, the verses in the reading
/// face. A multi-verse passage keeps its verse numbers so the boundaries stay
/// visible, and the text scales down only when it would overflow.
class ScriptureCard extends StatelessWidget {
  const ScriptureCard({
    super.key,
    required this.reference,
    required this.verses,
    required this.style,
    this.format = ShareCardFormat.status,
  });

  /// Full citation, e.g. `John 3:16–18`.
  final String reference;

  /// The selected verses in reading order.
  final List<ShareVerse> verses;

  final ShareCardStyle style;
  final ShareCardFormat format;

  @override
  Widget build(BuildContext context) {
    return ShareCardFrame(
      style: style,
      format: format,
      eyebrow: reference.toUpperCase(),
      body: (context, t) {
        final base = LumText.readingScripture.copyWith(color: t.textPrimary);
        final number = LumText.readingVerseNumber.copyWith(color: t.textAccent);
        return SizedBox(
          width: double.infinity,
          child: AutoSizeText.rich(
            TextSpan(
              children: [
                for (var i = 0; i < verses.length; i++) ...[
                  if (i > 0) const TextSpan(text: '  '),
                  if (verses.length > 1)
                    TextSpan(text: '${verses[i].number} ', style: number),
                  TextSpan(text: verses[i].text),
                ],
              ],
            ),
            style: base,
            minFontSize: 11,
            maxFontSize: 24,
            stepGranularity: 0.5,
          ),
        );
      },
    );
  }
}
