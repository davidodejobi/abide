import 'dart:ui';

import '../../domain/road_geometry.dart';
import '../../domain/road_landmarks.dart';

/// Landmark art is drawn at this size (design px): 70% of the old 105 x 90.
const landmarkSize = Size(73.5, 63);

/// A landmark never gets a tap target smaller than this (design px).
const landmarkMinHit = 44.0;

/// Clear gap kept between a landmark and any stop / other landmark (design px).
const landmarkStopGap = 8.0;
const landmarkGap = 6.0;

/// The footprint of a numbered stop (coin, ring and label) at world point
/// ([x] already includes the locked camera x), y in world px.
Rect stopFootprint(double x, double y) =>
    Rect.fromCenter(center: Offset(x, y + 2), width: 80, height: 56);

/// Smaller steps a crowded landmark may shrink to (1 = [landmarkSize]; the
/// last is about 55% of the original art size).
const landmarkScaleSteps = [1.0, .93, .86, .79];

/// World rect (camera dy = 0, camera dx = 195) of every landmark that fits on
/// the road, by id. A landmark stays within its own day's stretch of road
/// (halfway to the stops either side of its own, any distance from the road
/// that stays on screen) and is always nearer its own stop than any other.
/// Each landmark takes the smallest move that clears every stop and every
/// landmark placed before it, trying the full size first, then smaller steps.
/// First landmarks of every day are placed before second ones, so the
/// primary one is kept. One that fits nowhere is absent from the result: the
/// road skips it (its day's sheet still lists it). Pure and order-driven, so
/// identical on every rebuild and scroll position.
Map<String, Rect> layoutLandmarks(Map<int, List<Landmark>> byDay,
    {RoadGeometry geo = const RoadGeometry(), double centreX = 195}) {
  final days = byDay.keys.toList()..sort();
  final out = <String, Rect>{};
  final half = geo.spacing / 2;
  // Candidate (dx from own stop, dy from own stop), nearest first.
  final moves = <({double dx, double dy, double cost})>[];
  for (var dy = -half + 1; dy <= half - 1; dy += 4) {
    for (var dx = -centreX; dx <= centreX; dx += 4) {
      moves.add((dx: dx, dy: dy, cost: dx.abs() + dy.abs() * .5));
    }
  }
  moves.sort((a, b) => a.cost.compareTo(b.cost));
  for (var slot = 0; slot < 2; slot++) {
    for (final n in days) {
      final lms = byDay[n]!;
      if (slot >= lms.length) continue;
      final st = geo.stop(n);
      final own = Offset(centreX + st.x, st.y);
      final pref = (st.x > 0 ? 1.0 : -1.0) * (slot == 0 ? 1 : -1);
      Rect? pick;
      for (final k in landmarkScaleSteps) {
        final w = landmarkSize.width * k, h = landmarkSize.height * k;
        bool clear(Rect r) {
          if (r.left < 4 || r.right > centreX * 2 - 4) return false;
          final dOwn = (r.center - own).distance;
          for (var m = n - 3; m <= n + 3; m++) {
            if (m < 1) continue;
            final s = geo.stop(m);
            final at = Offset(centreX + s.x, s.y);
            if (m != n && (r.center - at).distance <= dOwn) return false;
            if (r.overlaps(
                stopFootprint(at.dx, at.dy).inflate(landmarkStopGap))) {
              return false;
            }
          }
          for (final p in out.values) {
            if (r.overlaps(p.inflate(landmarkGap))) return false;
          }
          return true;
        }

        // Preferred side first for equal cost: try that side's moves, then the
        // rest, but nearest wins overall.
        Rect? best;
        double bestCost = double.infinity;
        for (final m in moves) {
          final c = m.cost + (m.dx * pref < 0 ? 12 : 0);
          if (c >= bestCost) continue;
          final r = Rect.fromCenter(
              center: own.translate(m.dx, m.dy), width: w, height: h);
          if (clear(r)) {
            best = r;
            bestCost = c;
          }
        }
        if (best != null) {
          pick = best;
          break;
        }
      }
      if (pick != null) out[lms[slot].id] = pick;
    }
  }
  return out;
}

/// The one landmark that glows: the one standing closest to [day] (the day
/// being read), the earlier one on a tie. Null when there are none.
String? glowingLandmark(Map<int, List<Landmark>> byDay, int day,
    [Map<String, Rect>? onRoad]) {
  int? best;
  for (final n in byDay.keys) {
    if (!byDay[n]!.any((l) => onRoad == null || onRoad.containsKey(l.id))) {
      continue;
    }
    if (best == null ||
        (n - day).abs() < (best - day).abs() ||
        ((n - day).abs() == (best - day).abs() && n < best)) {
      best = n;
    }
  }
  return best == null
      ? null
      : byDay[best]!
          .firstWhere((l) => onRoad == null || onRoad.containsKey(l.id))
          .id;
}
