import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';

class HymnStanza extends StatelessWidget {
  final int number;
  final String text;
  final bool isChorus;

  /// Reader's font-size multiplier applied to the lyric text.
  final double textScale;

  const HymnStanza({
    super.key,
    required this.number,
    required this.text,
    this.isChorus = false,
    this.textScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    const base = LumText.readingLyrics;
    final size = base.fontSize! * textScale;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LumSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isChorus)
            SizedBox(
              width: 32,
              child: Text(
                '$number.',
                style: base.copyWith(
                    fontSize: size,
                    fontWeight: FontWeight.w700,
                    color: c.textAccent),
              ),
            ),
          Expanded(
            child: Text(
              text,
              style: base.copyWith(
                fontStyle: isChorus ? FontStyle.italic : FontStyle.normal,
                fontSize: size,
                color: c.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
