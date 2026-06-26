import 'package:flutter/material.dart';

/// The fixed set of highlight colors a reader can apply to a verse. Soft pastels
/// chosen to stay legible behind EBGaramond/Geist text on both light and dark
/// themes. [key] is what persists in `bible_annotations.color`.
enum HighlightColor {
  yellow('yellow', Color(0xFFFFF59D)),
  green('green', Color(0xFFC8E6C9)),
  blue('blue', Color(0xFFBBDEFB)),
  pink('pink', Color(0xFFF8BBD0)),
  purple('purple', Color(0xFFD1C4E9));

  const HighlightColor(this.key, this.swatch);

  final String key;
  final Color swatch;

  static HighlightColor? fromKey(String? k) {
    if (k == null) return null;
    for (final c in values) {
      if (c.key == k) return c;
    }
    return null;
  }
}
