import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

/// Horizontal drag distance, in logical px, for one full turn.
const dragPxPerTurn = 320.0;

/// Turns gained by dragging [dx] px: dragging right brings the near side
/// round to the right.
double dragTurns(double dx) => dx / dragPxPerTurn;

/// A fling of [vx] px/s as turns per second.
double flingTurnsPerSecond(double vx) => vx / dragPxPerTurn;

/// How the camera frames one landmark model: the same view the road sprites
/// were rendered from, so the 3D model lands exactly where the sprite sat.
class LandmarkFraming {
  const LandmarkFraming({
    required this.distance,
    required this.targetY,
    this.yawStartDeg = 0,
  });

  factory LandmarkFraming.fromJson(Map<String, dynamic> j) => LandmarkFraming(
        distance: (j['camera_distance'] as num).toDouble(),
        targetY: (j['camera_target_y'] as num).toDouble(),
        yawStartDeg: (j['yaw_start_deg'] as num? ?? 0).toDouble(),
      );

  /// Straight-line eye to target distance, in model units (metres).
  final double distance;

  /// Height of the point the camera looks at, on the model's vertical axis.
  final double targetY;
  final double yawStartDeg;

  /// Vertical field of view and look-down angle the manifest was built for.
  static const fovYDeg = 45.0;
  static const elevationDeg = 38.0;

  double get yawStartTurns => yawStartDeg / 360;

  /// The eye position (x, y, z). The model's front faces -Z once imported
  /// (glTF +Z, flipped to the engine's handedness), so the eye sits on -Z.
  (double, double, double) get eye {
    const e = elevationDeg * math.pi / 180;
    return (0, targetY + distance * math.sin(e), -distance * math.cos(e));
  }
}

/// Framing by landmark art key, from the bundled `manifest.json`.
Map<String, LandmarkFraming> parseFramings(String manifestJson) {
  final lm = (jsonDecode(manifestJson) as Map)['landmarks'] as Map;
  return {
    for (final e in lm.entries)
      e.key as String:
          LandmarkFraming.fromJson((e.value as Map).cast<String, dynamic>()),
  };
}

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
