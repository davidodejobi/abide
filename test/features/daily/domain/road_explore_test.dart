import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/daily/domain/road_days.dart';
import 'package:openbaptisthymnal/features/daily/domain/road_geometry.dart';
import 'package:openbaptisthymnal/features/daily/domain/road_landmarks.dart';

void main() {
  group('dateForDay', () {
    final today = DateTime(2026, 11, 25);
    test('today is the current day, later days follow one by one', () {
      expect(dateForDay(day: 41, currentDay: 41, today: today), today);
      expect(dateForDay(day: 44, currentDay: 41, today: today),
          DateTime(2026, 11, 28));
    });

    test('rolls over month and year ends', () {
      expect(dateForDay(day: 50, currentDay: 41, today: today),
          DateTime(2026, 12, 4));
      expect(dateForDay(day: 100, currentDay: 1, today: DateTime(2026, 12, 31)),
          DateTime(2027, 4, 9));
    });

    test('is calendar arithmetic, right across a DST change', () {
      // 2026-03-08 is the US spring-forward day: 24 h Durations would skip it.
      final d = dateForDay(day: 3, currentDay: 1, today: DateTime(2026, 3, 7));
      expect(d, DateTime(2026, 3, 9));
    });
  });

  group('explore camera', () {
    const geo = RoadGeometry();

    test('clampLook keeps the camera between the start and the last day', () {
      expect(clampLook(-3, 90), 0);
      expect(clampLook(12.5, 90), 12.5);
      expect(clampLook(400, 90), 90);
    });

    test('camera x is locked and focus follows the panel', () {
      for (final look in [0.0, 7.0, 8.0, 100.0]) {
        expect(geo.camera(look).x, 195);
      }
      expect(geo.camera(10, focus: 500).y - geo.camera(10).y, 500 - 300);
    });

    test('camera puts the looked-at stop at the focus height', () {
      for (final look in [0.0, 7.0, 100.0, 364.0]) {
        final cam = geo.camera(look);
        // The stop under the camera sits within a stop of the focus line.
        final y = geo.stop(look.round()).y + cam.y;
        expect((y - RoadGeometry.focusY).abs(), lessThan(geo.spacing));
      }
    });

    test('visibleStops covers exactly what can reach the screen', () {
      for (final look in [0.0, 3.4, 99.9, 250.0, 365.0]) {
        final v = geo.visibleStops(look);
        final cam = geo.camera(look);
        double screenY(int n) => geo.stop(n).y + cam.y;
        for (var n = v.first - 3; n <= v.last + 3; n++) {
          final onScreen = screenY(n) >= 120 && screenY(n) <= 580;
          if (onScreen) {
            expect(n >= v.first && n <= v.last, isTrue,
                reason: 'stop $n at y=${screenY(n)} look=$look');
          }
        }
        // Virtualised: a handful of stops, never the whole plan.
        expect(v.last - v.first, lessThan(14));
      }
    });
  });

  group('landmark_stories.json', () {
    final stories = parseLandmarkStories(
        File('assets/images/road/landmark_stories.json').readAsStringSync());
    final catalog = parseLandmarkCatalog(
        File('assets/images/road/landmarks.json').readAsStringSync(),
        File('assets/images/road/landmark_days.json').readAsStringSync());

    int sentences(String s) => RegExp(r'[.!?](\s|$)').allMatches(s).length;

    test('every landmark placed on a day has a story, and no story is spare',
        () {
      final ids = {
        for (final d in catalog.days) ...[d.story, if (d.also != null) d.alsoStory!],
      };
      expect(stories.keys.toSet(), ids);
    });

    test('a retelling is 1 to 6 sentences and why it matters is 1 or 2', () {
      for (final e in stories.entries) {
        expect(sentences(e.value.story), inInclusiveRange(1, 6), reason: e.key);
        expect(sentences(e.value.why), inInclusiveRange(1, 2), reason: e.key);
      }
    });

    test('house style: no em or en dashes', () {
      for (final e in stories.entries) {
        final text = '${e.value.story}${e.value.why}';
        expect(text.contains('—') || text.contains('–'), isFalse,
            reason: e.key);
      }
    });

    test('parse reads the id-keyed format', () {
      final s = parseLandmarkStories(jsonEncode({
        'x': {'story': 'A. B. C.', 'why': 'D.'}
      }));
      expect(s['x']!.why, 'D.');
    });
  });
}
