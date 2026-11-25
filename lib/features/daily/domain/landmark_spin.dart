import 'dart:typed_data';

/// A landmark turntable is one sheet of [spinFrames] frames in a
/// [spinColumns]-wide grid, one full turn, frame 0 facing the camera.
const spinFrames = 16;
const spinColumns = 4;

/// Horizontal drag distance, in logical px, for one full turn.
const dragPxPerTurn = 320.0;

/// The frame to show at [turns] (any real number; 1.0 is a full turn).
int spinFrameFor(double turns) {
  final f = turns - turns.floorToDouble();
  return (f * spinFrames).round() % spinFrames;
}

/// Turns gained by dragging [dx] px: dragging right brings the near side
/// round to the right, which is the direction the frames advance.
double dragTurns(double dx) => dx / dragPxPerTurn;

/// A fling of [vx] px/s as turns per second.
double flingTurnsPerSecond(double vx) => vx / dragPxPerTurn;

/// Up to [count] dominant, saturated colours of an RGBA image, as 0xAARRGGBB,
/// strongest first. Greys, whites and transparent pixels are ignored so the
/// palette is the landmark's own, not the ground's shadow.
List<int> spinPalette(Uint8List rgba, {int count = 3}) {
  final score = <int, double>{};
  for (var i = 0; i + 3 < rgba.length; i += 4 * 7) {
    final r = rgba[i], g = rgba[i + 1], b = rgba[i + 2], a = rgba[i + 3];
    if (a < 200) continue;
    final mx = r > g ? (r > b ? r : b) : (g > b ? g : b);
    final mn = r < g ? (r < b ? r : b) : (g < b ? g : b);
    final sat = mx == 0 ? 0.0 : (mx - mn) / mx;
    if (sat < .25 || mx < 70) continue;
    final key = (r >> 5) << 6 | (g >> 5) << 3 | (b >> 5);
    score[key] = (score[key] ?? 0) + sat;
  }
  final keys = score.keys.toList()..sort((a, b) => score[b]!.compareTo(score[a]!));
  return [
    for (final k in keys.take(count))
      0xFF000000 |
          (((k >> 6) << 5 | 16) << 16) |
          ((((k >> 3) & 7) << 5 | 16) << 8) |
          (((k & 7) << 5) | 16),
  ];
}
