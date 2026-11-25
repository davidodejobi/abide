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

/// World rect (camera dy = 0, camera dx = 195) of every landmark, by id.
///
/// Placed day by day, slot by slot: the landmark first tries to stand beside
/// its stop (outboard for slot 0, across the road for slot 1); if that rect
/// would touch a stop or an earlier landmark it slides along the road, then
/// tries the other side, taking the smallest move that is clear. Pure and
/// order-driven, so it is identical on every rebuild and scroll position.

Map<String, Rect> layoutLandmarks(Map<int, List<Landmark>> byDay,
    {RoadGeometry geo = const RoadGeometry(), double centreX = 195}) {
  final w = landmarkSize.width, h = landmarkSize.height;
  final days = byDay.keys.toList()..sort();
  final out = <String, Rect>{};
  final placed = <Rect>[];
  // Candidate (dx, dy) moves, cheapest first.
  final moves = <({double dx, double dy, int side, double cost})>[];
  for (var s = 0; s <= 240; s += 8) {
    for (final dy in s == 0 ? [0.0] : [-s.toDouble(), s.toDouble()]) {
      for (var i = 0; i < 8; i++) {
        for (final side in [1, -1]) {
          moves.add((
            dx: i * 24.0,
            dy: dy,
            side: side,
            cost: s + i * 3.0 + (side == 1 ? 0 : 20),
          ));
        }
      }
    }
  }
  moves.sort((a, b) => a.cost.compareTo(b.cost));
  for (final n in days) {
    final st = geo.stop(n);
    final lms = byDay[n]!;
    for (var slot = 0; slot < lms.length; slot++) {
      final pref = (st.x > 0 ? 1.0 : -1.0) * (slot == 0 ? 1 : -1);
      Rect at(double dx, double dy, int side) {
        final cx = (centreX + st.x + pref * side * dx)
            .clamp(w / 2 + 4, centreX * 2 - w / 2 - 4);
        final bottom = st.y + 18 + dy;
        return Rect.fromLTWH(cx - w / 2, bottom - h * .86, w, h);
      }

      bool clear(Rect r) {
        for (var m = n - 5; m <= n + 5; m++) {
          if (m < 1) continue;
          final s = geo.stop(m);
          if (r.overlaps(
              stopFootprint(centreX + s.x, s.y).inflate(landmarkStopGap))) {
            return false;
          }
        }
        for (final p in placed) {
          if (r.overlaps(p.inflate(landmarkGap))) return false;
        }
        return true;
      }

      Rect? pick;
      for (final m in moves) {
        final r = at(m.dx, m.dy, m.side);
        if (clear(r)) {
          pick = r;
          break;
        }
      }
      pick ??= at(72, 0, 1); // ponytail: unreachable on bundled plans (tested)
      out[lms[slot].id] = pick;
      placed.add(pick);
    }
  }
  return out;
}

/// The one landmark that glows: the one standing closest to [day] (the day
/// being read), the earlier one on a tie. Null when there are none.
String? glowingLandmark(Map<int, List<Landmark>> byDay, int day) {
  int? best;
  for (final n in byDay.keys) {
    if (byDay[n]!.isEmpty) continue;
    if (best == null ||
        (n - day).abs() < (best - day).abs() ||
        ((n - day).abs() == (best - day).abs() && n < best)) {
      best = n;
    }
  }
  return best == null ? null : byDay[best]!.first.id;
}
