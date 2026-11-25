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

  /// Where the camera looks: the stop position [look] sits at this screen y.
  static const double focusY = 300;

  /// Screen offset to add to a world point so that stop position [look] sits at
  /// [focus] (design px from the scene top; the scene moves it as the reading
  /// panel slides). x is locked to the road's centre: the road swings left and
  /// right in view while the camera only ever moves vertically.
  math.Point<double> camera(double look, {double focus = focusY}) {
    final p = at(look + .25);
    return math.Point(195, focus - p.y);
  }

  /// The stops whose screen y can fall within [top]..[bottom] when the camera
  /// looks at [look]; one stop of margin each side. Stop 0 is the road's start,
  /// so [first] may be below 1 (props stand there too); the caller clamps to
  /// the plan. Stop `n` is at screen y `focusY + (look + .25 - n) * spacing`.
  ({int first, int last}) visibleStops(double look,
      {double top = 120, double bottom = 580, double focus = focusY}) {
    final base = focus + (look + .25) * spacing;
    return (
      first: ((base - bottom) / spacing).floor() - 1,
      last: ((base - top) / spacing).ceil() + 1,
    );
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
