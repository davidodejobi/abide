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

/// Podium depth below its top face, as a fraction of its radius (podium.glb).
const podiumDepth = .19;

/// Podium radius as a multiple of the model's ground footprint radius.
const podiumFootprintScale = 1.2;

/// Where the podium centre sits in the view, in NDC y (-1 is the bottom), so
/// the stage's spotlight lands on it.
const podiumAnchorY = -.40;

/// How the camera frames one landmark on its podium, one view for both.
///
/// The podium is sized from the model's ground footprint; the camera is then
/// pulled back, and its target moved, until the model's box and the whole
/// podium rim fit the view with the podium centre at [podiumAnchorY].
class LandmarkFraming {
  const LandmarkFraming({
    required this.distance,
    required this.targetY,
    this.yawStartDeg = 0,
    this.podiumRadius = 1,
  });

  /// Fits the camera to a model with the given bounds (glTF space, metres).
  factory LandmarkFraming.fit({
    required List<double> boundsMin,
    required List<double> boundsMax,
    required double baseDistance,
    double yawStartDeg = 0,
  }) {
    final hx = math.max(boundsMin[0].abs(), boundsMax[0].abs());
    final hz = math.max(boundsMin[2].abs(), boundsMax[2].abs());
    final radius = podiumFootprintScale * math.sqrt(hx * hx + hz * hz);
    final height = boundsMax[1];
    final pts = <(double, double, double)>[
      for (final x in [-hx, hx])
        for (final y in [0.0, height])
          for (final z in [-hz, hz]) (x, y, z),
      for (var i = 0; i < 24; i++)
        for (final y in [0.0, -podiumDepth * radius])
          (
            radius * math.cos(i * math.pi / 12),
            y,
            radius * math.sin(i * math.pi / 12),
          ),
    ];
    var d = baseDistance * .5;
    for (var n = 0; n < 120; n++, d *= 1.03) {
      // Bisect the target height that puts the podium centre at the anchor:
      // raising the target moves the centre down the view.
      var lo = -radius * 3, hi = height * 2 + radius * 3;
      for (var k = 0; k < 40; k++) {
        final mid = (lo + hi) / 2;
        if (ndc((0, 0, 0), d, mid).$2 > podiumAnchorY) {
          lo = mid;
        } else {
          hi = mid;
        }
      }
      final ty = (lo + hi) / 2;
      final fits = pts.every((p) {
        final (x, y) = ndc(p, d, ty);
        return x.abs() <= viewFill &&
            y <= (p.$2 > 0 ? topFill : viewFill) &&
            y >= -viewFill;
      });
      if (fits) {
        return LandmarkFraming(
          distance: d,
          targetY: ty,
          yawStartDeg: yawStartDeg,
          podiumRadius: radius,
        );
      }
    }
    return LandmarkFraming(
        distance: d, targetY: height / 2, yawStartDeg: yawStartDeg, podiumRadius: radius);
  }

  factory LandmarkFraming.fromJson(Map<String, dynamic> j) {
    List<double> v(String k) =>
        [for (final n in j[k] as List) (n as num).toDouble()];
    return LandmarkFraming.fit(
      boundsMin: v('bounds_min'),
      boundsMax: v('bounds_max'),
      baseDistance: (j['camera_distance'] as num).toDouble(),
      yawStartDeg: (j['yaw_start_deg'] as num? ?? 0).toDouble(),
    );
  }

  /// Straight-line eye to target distance, in model units (metres).
  final double distance;

  /// Height of the point the camera looks at, on the model's vertical axis.
  final double targetY;
  final double yawStartDeg;

  /// Radius of the static podium under the model, in metres.
  final double podiumRadius;

  /// Vertical field of view and look-down angle: a three-quarter view of the
  /// podium.
  static const fovYDeg = 20.0;
  static const elevationDeg = 24.0;

  /// Width over height of the 3D view box.
  static const aspect = 320 / 260;

  /// How much of the view (NDC) the fitted content may use.
  static const viewFill = .97;

  /// How high the model top may reach (NDC), leaving room for the close button.
  static const topFill = .8;

  double get yawStartTurns => yawStartDeg / 360;

  /// The eye position (x, y, z). The model's front faces -Z once imported
  /// (glTF +Z, flipped to the engine's handedness), so the eye sits on -Z.
  (double, double, double) get eye => _eye(distance, targetY);

  /// Where a model-space point lands in the view (NDC, +y up) under this
  /// framing.
  (double, double) project((double, double, double) p) =>
      ndc(p, distance, targetY);

  static (double, double, double) _eye(double d, double ty) {
    const e = elevationDeg * math.pi / 180;
    return (0, ty + d * math.sin(e), -d * math.cos(e));
  }

  /// Perspective projection of [p] for a camera [d] away, looking at height
  /// [ty] on the vertical axis from the fixed elevation.
  static (double, double) ndc((double, double, double) p, double d, double ty) {
    const e = elevationDeg * math.pi / 180;
    // Camera basis: forward looks down and toward +Z; up is perpendicular.
    final fy = -math.sin(e), fz = math.cos(e);
    final uy = math.cos(e), uz = math.sin(e);
    final (_, ey, ez) = _eye(d, ty);
    final dy = p.$2 - ey, dz = p.$3 - ez;
    final depth = dy * fy + dz * fz;
    final t = math.tan(fovYDeg * math.pi / 360);
    return (p.$1 / (depth * t * aspect), (dy * uy + dz * uz) / (depth * t));
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
