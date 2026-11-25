import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/features/share_card/ui/share_card_style.dart';
import 'package:openbaptisthymnal/features/share_card/ui/widgets/share_card_frame.dart';
import 'package:openbaptisthymnal/features/tablet/ui/notes_strings.dart';

/// The hymn card: the hymn number as the eyebrow, the title, then the lyrics.
/// The frame scales the road and text so the whole stanza fits.
class LyricCard extends StatelessWidget {
  const LyricCard({
    super.key,
    required this.hymnNumber,
    required this.title,
    required this.body,
    required this.style,
    this.format = ShareCardFormat.status,
  });

  final String hymnNumber;
  final String title;
  final String body;
  final ShareCardStyle style;
  final ShareCardFormat format;

  @override
  Widget build(BuildContext context) {
    return ShareCardFrame(
      style: style,
      format: format,
      eyebrow: NotesStrings.hymnEyebrow(hymnNumber),
      span: (t) => TextSpan(
        children: [
          TextSpan(
            text: '$title\n\n',
            style: LumText.title3.copyWith(color: t.textPrimary),
          ),
          TextSpan(
            text: body,
            style: LumText.readingLyrics.copyWith(color: t.textPrimary),
          ),
        ],
      ),
    );
  }
}
