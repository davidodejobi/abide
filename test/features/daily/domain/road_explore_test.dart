import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/bible/domain/verse_ref.dart';
import 'package:openbaptisthymnal/features/daily/domain/reading_plan.dart';
import 'package:openbaptisthymnal/features/daily/domain/road_days.dart';
import 'package:openbaptisthymnal/features/daily/domain/road_geometry.dart';
import 'package:openbaptisthymnal/features/daily/domain/road_landmarks.dart';

Landmark _lm(String id, String book, int from, int to, String ref,
        {String? art}) =>
    Landmark(
      id: id,
      book: book,
      fromChapter: from,
      toChapter: to,
      title: id,
      short: id,
      ref: ref,
      art: art,
    );

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

  group('landmarks on the road', () {
    final plan = ReadingPlan(id: 'p', title: '', description: '', days: [
      PlanDay(dayIndex: 1, passages: [VerseRange.tryParse('GEN.1.1-3.24')!]),
      PlanDay(dayIndex: 2, passages: [VerseRange.tryParse('GEN.4.1-5.32')!]),
      PlanDay(dayIndex: 3, passages: [VerseRange.tryParse('GEN.6.1-9.29')!]),
    ]);

    test('without placeArtless a landmark with no art is not on the road', () {
      final all = [_lm('garden', 'GEN', 1, 2, 'Genesis 1:1')];
      expect(landmarksByDay(plan, all), isEmpty);
    });

    test('with placeArtless it stands at its day as a marker', () {
      final all = [
        _lm('garden', 'GEN', 1, 2, 'Genesis 1:1'),
        _lm('ark', 'GEN', 6, 9, 'Genesis 6:14', art: 'ark'),
      ];
      final m = landmarksByDay(plan, all, placeArtless: true);
      expect(m.map((d, l) => MapEntry(d, l.map((x) => x.id).toList())), {
        1: ['garden'],
        3: ['ark'],
      });
    });

    test('openingKey reads the verse off the reference', () {
      expect(_lm('a', 'GEN', 1, 2, 'Genesis 1:1').openingKey, 'GEN.1.1');
      expect(_lm('a', '1SA', 17, 17, '1 Samuel 17:40').openingKey, '1SA.17.40');
      expect(
          _lm('a', 'PSA', 119, 119, 'Psalm 119:105').openingKey, 'PSA.119.105');
      expect(_lm('a', 'PSA', 23, 23, 'Psalm 23').openingKey, 'PSA.23.1');
    });

    test('every landmark opens at a reference the Bible link parser accepts',
        () {
      final all = parseLandmarks(
          File('assets/images/road/landmarks.json').readAsStringSync());
      for (final l in all) {
        expect(VerseRange.tryParse(l.openingKey), isNotNull, reason: l.id);
      }
    });
  });

  group('landmark_stories.json', () {
    final stories = parseLandmarkStories(
        File('assets/images/road/landmark_stories.json').readAsStringSync());
    final landmarks = parseLandmarks(
        File('assets/images/road/landmarks.json').readAsStringSync());

    int sentences(String s) => RegExp(r'[.!?](\s|$)').allMatches(s).length;

    test('every story belongs to a landmark, and every drawn landmark has one',
        () {
      final ids = landmarks.map((l) => l.id).toSet();
      expect(ids.containsAll(stories.keys), isTrue);
      expect(
          stories.keys.toSet().containsAll(
              landmarks.where((l) => l.art != null).map((l) => l.id)),
          isTrue);
    });

    test('a retelling is 3 to 6 sentences and why it matters is 1 or 2', () {
      for (final e in stories.entries) {
        expect(sentences(e.value.story), inInclusiveRange(3, 6), reason: e.key);
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
