import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/daily/domain/reading_plan.dart';
import 'package:openbaptisthymnal/features/daily/domain/road_geometry.dart';
import 'package:openbaptisthymnal/features/daily/domain/road_landmarks.dart';
import 'package:openbaptisthymnal/features/daily/ui/widgets/landmark_layout.dart';

void main() {
  final plan = ReadingPlan.fromJson(
      jsonDecode(File('assets/plans/bible-in-a-year.json').readAsStringSync())
          as Map<String, dynamic>);
  final all = parseLandmarks(
      File('assets/images/road/landmarks.json').readAsStringSync());
  final byDay = landmarksByDay(plan, all, placeArtless: true);
  final layout = layoutLandmarks(byDay);
  const geo = RoadGeometry();

  test('landmarks are 70% of the old size and keep a 44pt hit target', () {
    expect(landmarkSize.width, closeTo(105 * .7, .1));
    expect(landmarkSize.height, closeTo(90 * .7, .1));
    expect(landmarkSize.shortestSide, greaterThanOrEqualTo(landmarkMinHit));
  });

  void checkClear(Iterable<MapEntry<int, List<Landmark>>> days) {
    for (final e in days) {
      for (final l in e.value) {
        final r = layout[l.id];
        if (r == null) continue; // skipped on the road
        expect(r.left, greaterThanOrEqualTo(0));
        expect(r.right, lessThanOrEqualTo(390));
        final own = geo.stop(e.key);
        final dOwn = (r.center - Offset(195 + own.x, own.y)).distance;
        expect((r.center.dy - own.y).abs(), lessThan(geo.spacing / 2),
            reason: '${l.id} leaves its own stretch of road');
        for (var n = e.key - 6; n <= e.key + 6; n++) {
          if (n < 1) continue;
          final s = geo.stop(n);
          if (n != e.key) {
            expect(
                (r.center - Offset(195 + s.x, s.y)).distance, greaterThan(dOwn),
                reason: '${l.id} is nearer stop $n than its own ${e.key}');
          }
          expect(
              r.overlaps(
                  stopFootprint(195 + s.x, s.y).inflate(landmarkStopGap)),
              isFalse,
              reason: '${l.id} overlaps stop $n');
        }
        for (final o in layout.entries) {
          if (o.key == l.id) continue;
          expect(r.overlaps(o.value.inflate(landmarkGap)), isFalse,
              reason: '${l.id} overlaps ${o.key}');
        }
      }
    }
  }

  test('first 60 days: nothing touches, each landmark nearest its own stop',
      () {
    final first = byDay.entries.where((e) => e.key <= 60).toList();
    expect(first.expand((e) => e.value).length, greaterThan(5));
    for (final e in first) {
      expect(layout.containsKey(e.value.first.id), isTrue);
    }
    checkClear(first);
  });

  test('the whole year, dense gospel days included, is clear and local', () {
    checkClear(byDay.entries);
    final skipped = [
      for (final e in byDay.entries)
        for (final l in e.value)
          if (!layout.containsKey(l.id)) '${e.key}:${l.id}',
    ];
    // ignore: avoid_print
    print('skipped on the road: ${skipped.length} $skipped');
    // A day's first landmark is never the one dropped.
    for (final e in byDay.entries) {
      expect(layout.containsKey(e.value.first.id), isTrue,
          reason: 'primary landmark of day ${e.key} was skipped');
    }
  });

  test('layout is deterministic', () {
    expect(layoutLandmarks(byDay), layout);
  });

  test('exactly one landmark glows, the nearest to the day being read', () {
    for (final day in [1, 2, 17, 60, 365]) {
      final g = glowingLandmark(byDay, day, layout)!;
      final at =
          byDay.entries.firstWhere((e) => e.value.any((l) => l.id == g)).key;
      final dist = (at - day).abs();
      for (final e in byDay.entries) {
        expect((e.key - day).abs(), greaterThanOrEqualTo(dist));
      }
    }
    expect(glowingLandmark(const {}, 3), isNull);
  });
}
