import 'package:flutter/material.dart';

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
    // Base reading size mirrors the lyric body style used elsewhere.
    const baseSize = 16.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isChorus)
            SizedBox(
              width: 30,
              child: Text(
                '$number.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: baseSize * textScale,
                ),
              ),
            ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontStyle: isChorus ? FontStyle.italic : FontStyle.normal,
                fontWeight: isChorus ? FontWeight.w500 : FontWeight.normal,
                fontSize: baseSize * textScale,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
