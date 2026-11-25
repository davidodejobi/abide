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

  test('first 60 days: no landmark touches a stop or another landmark', () {
    final ids = [
      for (var n = 1; n <= 60; n++) ...?byDay[n]?.map((l) => l.id),
    ];
    expect(ids.length, greaterThan(5));
    for (final id in ids) {
      final r = layout[id]!;
      expect(r.left, greaterThanOrEqualTo(0));
      expect(r.right, lessThanOrEqualTo(390));
      for (var n = 1; n <= 70; n++) {
        final s = geo.stop(n);
        expect(
            r.overlaps(stopFootprint(195 + s.x, s.y).inflate(landmarkStopGap)),
            isFalse,
            reason: '$id overlaps stop $n');
      }
      for (final o in ids) {
        if (o == id) continue;
        expect(r.overlaps(layout[o]!.inflate(landmarkGap)), isFalse,
            reason: '$id overlaps $o');
      }
    }
  });

  test(
      'the whole year, dense gospel days included, is clear of stops and each other',
      () {
    for (final e in byDay.entries) {
      for (final l in e.value) {
        final r = layout[l.id]!;
        for (var n = e.key - 5; n <= e.key + 5; n++) {
          if (n < 1) continue;
          final s = geo.stop(n);
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
  });

  test('layout is deterministic', () {
    expect(layoutLandmarks(byDay), layout);
  });

  test('exactly one landmark glows, the nearest to the day being read', () {
    for (final day in [1, 2, 17, 60, 365]) {
      final g = glowingLandmark(byDay, day)!;
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
