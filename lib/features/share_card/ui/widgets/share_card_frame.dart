import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/features/share_card/ui/share_card_style.dart';

/// The card that gets captured: road on top, then a solid panel with an
/// eyebrow, the words and the Lumway mark. Text never sits over art. Used by
/// both the scripture and the hymn card; [body] builds the words for the room
/// the panel has left.
class ShareCardFrame extends StatelessWidget {
  const ShareCardFrame({
    super.key,
    required this.style,
    required this.format,
    required this.eyebrow,
    required this.body,
  });

  final ShareCardStyle style;
  final ShareCardFormat format;
  final String eyebrow;
  final Widget Function(BuildContext context, LumColors tone) body;

  @override
  Widget build(BuildContext context) {
    final t = style.tone;
    final road = style.roadAsset;
    return AspectRatio(
      aspectRatio: format.aspect,
      child: LayoutBuilder(
        builder: (context, box) {
          final roadHeight =
              box.maxWidth * (format == ShareCardFormat.status ? 0.62 : 0.38);
          return ColoredBox(
            color: t.glassFillOpaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (road != null)
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
                        Text(
                          eyebrow,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LumText.roadLabelCaps11
                              .copyWith(color: t.textSecondary),
                        ),
                        const SizedBox(height: LumSpace.md),
                        Expanded(child: body(context, t)),
                        const SizedBox(height: LumSpace.md),
                        Text(
                          'Lumway',
                          style: LumText.footnoteEmphasized
                              .copyWith(color: t.textPrimary),
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
