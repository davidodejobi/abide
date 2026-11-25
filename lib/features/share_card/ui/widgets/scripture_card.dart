import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/features/share_card/ui/scripture_share_card_page.dart'
    show ShareVerse;
import 'package:openbaptisthymnal/features/share_card/ui/share_card_style.dart';
import 'package:openbaptisthymnal/features/share_card/ui/widgets/share_card_frame.dart';

/// The scripture card: the reference as the eyebrow, the verses in the reading
/// face. A multi-verse passage keeps its verse numbers so the boundaries stay
/// visible. The frame scales the road and text so every verse fits.
class ScriptureCard extends StatelessWidget {
  const ScriptureCard({
    super.key,
    required this.reference,
    required this.verses,
    required this.style,
    this.format = ShareCardFormat.status,
    this.showReference = true,
  });

  /// Full citation, e.g. `John 3:16–18`.
  final String reference;

  /// The selected verses in reading order.
  final List<ShareVerse> verses;

  final ShareCardStyle style;
  final ShareCardFormat format;

  /// Whether the citation shows above the verses.
  final bool showReference;

  @override
  Widget build(BuildContext context) {
    return ShareCardFrame(
      style: style,
      format: format,
      eyebrow: showReference ? reference.toUpperCase() : null,
      span: (t) {
        final base = LumText.readingScripture.copyWith(color: t.textPrimary);
        final number = LumText.readingVerseNumber.copyWith(color: t.textAccent);
        return TextSpan(
          style: base,
          children: [
            for (var i = 0; i < verses.length; i++) ...[
              if (i > 0) const TextSpan(text: '  '),
              if (verses.length > 1)
                TextSpan(text: '${verses[i].number} ', style: number),
              TextSpan(text: verses[i].text),
            ],
          ],
        );
      },
    );
  }
}
