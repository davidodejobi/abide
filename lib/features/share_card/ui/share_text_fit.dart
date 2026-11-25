import 'package:flutter/painting.dart';

/// How a share card lays out its words: how much of the road band to keep, the
/// text scale, and a line cap when even the smallest readable size would not fit.
class ShareTextFit {
  const ShareTextFit({
    required this.roadFraction,
    required this.scale,
    this.maxLines,
  });

  /// Share of the full road band to keep (1 = full, 0 = no road).
  final double roadFraction;

  /// Text scale applied to [span]'s own sizes.
  final double scale;

  /// Set only when the text still overflows at the smallest size with no road;
  /// the card then ends the text with an ellipsis.
  final int? maxLines;
}

const _roadSteps = [1.0, 0.5, 0.0];
// The card exports about 3.6x its preview size, so even 0.5 stays legible.
const _scales = [1.0, 0.9, 0.8, 0.7, 0.6, 0.5];

/// Picks the road band and text scale so the whole of [span] fits in a card of
/// [cardHeight]. At each text size it keeps as much road as fits, shrinking the
/// road before the text, and only caps the text
/// with an ellipsis when it cannot fit even with no road at the smallest scale.
ShareTextFit fitShareText({
  required TextSpan span,
  required double textWidth,
  required double cardHeight,
  required double fullRoad,

  /// Height the panel spends on padding, eyebrow and footer.
  required double chrome,
  TextDirection textDirection = TextDirection.ltr,
}) {
  TextPainter paint(double scale, {int? maxLines}) => TextPainter(
        text: span,
        textDirection: textDirection,
        textScaler: TextScaler.linear(scale),
        maxLines: maxLines,
        ellipsis: maxLines == null ? null : '…',
      )..layout(maxWidth: textWidth);

  // Full size first; each step down in text size gets another try at the road.
  for (final scale in _scales) {
    final height = paint(scale).height;
    for (final step in _roadSteps) {
      final room = cardHeight - fullRoad * step - chrome;
      if (height <= room) {
        return ShareTextFit(roadFraction: step, scale: scale);
      }
    }
  }

  const floor = 0.5;
  final room = cardHeight - chrome;
  final line = paint(floor).computeLineMetrics();
  final lineHeight = line.isEmpty ? 16.0 : line.first.height;
  final lines = (room / lineHeight).floor().clamp(1, 1000);
  return ShareTextFit(roadFraction: 0, scale: floor, maxLines: lines);
}
