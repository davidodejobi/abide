import 'dart:math' as math;

/// Where the road runs, in design pixels. Stop `n` (1-based; 0 is the start of
/// the road) sits `spacing` px above stop `n - 1`, swinging left and right.
/// Pure maths so the walk can be tested without a canvas.
class RoadGeometry {
  const RoadGeometry({this.spacing = 62, this.sway = 82});

  final double spacing;
  final double sway;

  /// The stop's position, x relative to the road's centre line, y growing
  /// downward (the road climbs towards negative y).
  math.Point<double> stop(int n) {
    final side = n.isOdd ? -1.0 : 1.0;
    final wobble = 0.8 + 0.2 * math.sin(n * 1.7);
    return math.Point(side * sway * wobble, -n * spacing);
  }

  /// A smooth point along the road at fractional stop position [pos], via a
  /// Catmull-Rom spline through the stops, so a walker eased through [pos]
  /// follows the bends instead of cutting corners.
  math.Point<double> at(double pos) {
    final p = pos < 0 ? 0.0 : pos;
    final i = p.floor();
    final t = p - i;
    final p0 = stop(i - 1), p1 = stop(i), p2 = stop(i + 1), p3 = stop(i + 2);
    double c(double a, double b, double cc, double d) =>
        0.5 *
        ((2 * b) +
            (-a + cc) * t +
            (2 * a - 5 * b + 4 * cc - d) * t * t +
            (-a + 3 * b - 3 * cc + d) * t * t * t);
    return math.Point(c(p0.x, p1.x, p2.x, p3.x), c(p0.y, p1.y, p2.y, p3.y));
  }
}
