import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/features/share_card/ui/share_card_style.dart';
import 'package:openbaptisthymnal/features/share_card/ui/share_text_fit.dart';

const _mark = 'Lumway';

/// The card that gets captured: road on top, then a solid panel with an
/// eyebrow, the words and the Lumway mark. Text never sits over art. Used by
/// both the scripture and the hymn card; [body] builds the words for the room
/// the panel has left.
class ShareCardFrame extends StatelessWidget {
  const ShareCardFrame({
    super.key,
    required this.style,
    required this.format,
    this.eyebrow,
    required this.span,
  });

  final ShareCardStyle style;
  final ShareCardFormat format;
  /// Reference line above the words; null hides it.
  final String? eyebrow;

  /// The words, styled with the card's tone. The frame scales them to fit.
  final TextSpan Function(LumColors tone) span;

  @override
  Widget build(BuildContext context) {
    final t = style.tone;
    final road = style.roadAsset;
    return AspectRatio(
      aspectRatio: format.aspect,
      child: LayoutBuilder(
        builder: (context, box) {
          final fullRoad = road == null
              ? 0.0
              : box.maxWidth * (format == ShareCardFormat.status ? 0.62 : 0.38);
          final eyebrowStyle =
              LumText.roadLabelCaps11.copyWith(color: t.textSecondary);
          final footerStyle =
              LumText.footnoteEmphasized.copyWith(color: t.textPrimary);
          double lineHeight(String text, TextStyle st) => (TextPainter(
                text: TextSpan(text: text, style: st),
                textDirection: TextDirection.ltr,
                textScaler: TextScaler.noScaling,
              )..layout())
                  .height;
          // Padding top and bottom, the two gaps, the eyebrow and the footer.
          final chrome = 2 * LumSpace.xl +
              2 * LumSpace.md +
              (eyebrow == null
                  ? -LumSpace.md
                  : lineHeight(eyebrow!, eyebrowStyle)) +
              lineHeight(_mark, footerStyle) +
              1;
          final words = span(t);
          final fit = fitShareText(
            span: words,
            textWidth: box.maxWidth - 2 * LumSpace.xl,
            cardHeight: box.maxHeight,
            fullRoad: fullRoad,
            chrome: chrome,
          );
          final roadHeight = fullRoad * fit.roadFraction;
          return ColoredBox(
            color: t.glassFillOpaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (road != null && roadHeight > 0)
                  ExcludeSemantics(
                    child: SizedBox(
                      height: roadHeight,
                      child: Image.asset(
                        road,
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, 0.4),
                        errorBuilder: (_, __, ___) =>
                            ColoredBox(color: t.bgSurfaceSunken),
                      ),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(LumSpace.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (eyebrow != null) ...[
                          Text(
                            eyebrow!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: eyebrowStyle,
                          ),
                          const SizedBox(height: LumSpace.md),
                        ],
                        Expanded(
                          child: Text.rich(
                            words,
                            textScaler: TextScaler.linear(fit.scale),
                            maxLines: fit.maxLines,
                            overflow: fit.maxLines == null
                                ? TextOverflow.clip
                                : TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: LumSpace.md),
                        Text(
                          _mark,
                          style: footerStyle,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
