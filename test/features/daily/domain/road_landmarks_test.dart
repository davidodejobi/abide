import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/bible/domain/verse_ref.dart';
import 'package:openbaptisthymnal/features/daily/domain/reading_plan.dart';
import 'package:openbaptisthymnal/features/daily/domain/road_geometry.dart';
import 'package:openbaptisthymnal/features/daily/domain/road_landmarks.dart';

ReadingPlan _plan(String id) => ReadingPlan.fromJson(
    jsonDecode(File('assets/plans/$id.json').readAsStringSync())
        as Map<String, dynamic>);

CatalogDay _day(int n, String art, String chapters, {String? also}) => CatalogDay(
      day: n,
      art: art,
      story: 'd$n-$art',
      title: art,
      ref: 'Genesis $n',
      spans: [
        ('GEN', int.parse(chapters.split('-')[0]), int.parse(chapters.split('-')[1]))
      ],
      also: also,
      alsoStory: also == null ? null : 'd$n-$also',
    );

LandmarkCatalog _catalog(List<CatalogDay> days, {String plan = 'p'}) =>
    LandmarkCatalog(plan: plan, models: const {}, days: days);

ReadingPlan _simplePlan(int days, {String id = 'p'}) => ReadingPlan(
    id: id,
    title: '',
    description: '',
    days: [
      for (var i = 1; i <= days; i++)
        PlanDay(
            dayIndex: i, passages: [VerseRange.tryParse('GEN.$i.1-$i.5')!]),
    ]);

void main() {
  final real = parseLandmarkCatalog(
      File('assets/images/road/landmarks.json').readAsStringSync(),
      File('assets/images/road/landmark_days.json').readAsStringSync());

  group('the bundled catalog', () {
    test('127 models, each with a sprite; 365 days that all resolve', () {
      expect(real.models.length, 127);
      for (final m in real.models.values) {
        expect(File('assets/images/road/living/lm_${m.art}.webp').existsSync(),
            isTrue,
            reason: m.art);
        expect(m.sha256.length, 64);
        // Only bundled models may rely on a glb in the app.
        expect(File('assets/images/road/models/${m.art}.glb').existsSync(),
            m.bundled,
            reason: m.art);
      }
      expect(real.days.length, 365);
      for (final d in real.days) {
        expect(real.models.containsKey(d.art), isTrue, reason: 'day ${d.day}');
        if (d.also != null) {
          expect(real.models.containsKey(d.also), isTrue, reason: 'day ${d.day}');
        }
      }
    });

    test('bible-in-a-year: every day has a landmark and it is the day mapped',
        () {
      final plan = _plan('bible-in-a-year');
      final m = landmarksByDay(plan, real);
      // The first day is the garden, day 271 (moved) is the potter, and the
      // map never holds a day outside the plan or more than two landmarks.
      expect(m[1]!.first.art, 'garden');
      expect(m[271]!.first.art, 'potter');
      expect(m[270]!.map((l) => l.art), containsAll(['lampstand']));
      expect(m.keys.every((d) => d >= 1 && d <= 365), isTrue);
      expect(m.values.every((l) => l.length <= 2), isTrue);
      // Reused landmarks thin out a few days, but most days keep theirs.
      expect(m.length, greaterThan(330));
    });

    test('bible-in-a-year: the same art never stands within 4 days of itself',
        () {
      final m = landmarksByDay(_plan('bible-in-a-year'), real);
      final last = <String, int>{};
      for (final day in (m.keys.toList()..sort())) {
        for (final l in m[day]!) {
          final prev = last[l.art];
          expect(prev == null || day - prev >= 4, isTrue,
              reason: '${l.art} on $day and $prev');
          last[l.art!] = day;
        }
      }
    });

    for (final id in ['nt-90', 'psalms-30']) {
      test('$id: landmarks come from the catalog day that holds the chapters',
          () {
        final plan = _plan(id);
        final m = landmarksByDay(plan, real);
        expect(m, isNotEmpty);
        m.forEach((day, lms) {
          final s = plan.dayAt(day)!.passages.first.start;
          final cd = real.dayFor(plan, plan.dayAt(day)!)!;
          expect(cd.covers(s.book, s.chapter), isTrue);
          expect(lms.first.id, anyOf(cd.story, cd.alsoStory));
        });
        // A catalog day is shown once even if several plan days sit in it.
        final ids = m.values.expand((l) => l).map((l) => l.id).toList();
        expect(ids.toSet().length, ids.length);
      });
    }

    test('every landmark opens at a reference the Bible link parser accepts',
        () {
      for (final l in landmarksByDay(_plan('bible-in-a-year'), real)
          .values
          .expand((l) => l)) {
        expect(VerseRange.tryParse(l.openingKey), isNotNull, reason: l.id);
      }
    });
  });

  group('day mapping and the repeat rule', () {
    test('the catalog plan maps by day number, other plans by chapter', () {
      final cat = _catalog([
        _day(1, 'garden', '1-1'),
        _day(2, 'ark', '2-3', also: 'rainbow'),
      ], plan: 'q');
      final same = landmarksByDay(_simplePlan(2, id: 'q'), cat);
      expect(same[2]!.map((l) => l.art), ['ark', 'rainbow']);
      // A different plan: its day 3 starts at Genesis 3, which catalog day 2 holds.
      final other = landmarksByDay(_simplePlan(3), cat);
      expect(other[1]!.single.art, 'garden');
      expect(other[2]!.map((l) => l.art), ['ark', 'rainbow']);
      expect(other.containsKey(3), isFalse, reason: 'catalog day 2 shown once');
    });

    test('a landmark never stands next to a copy of itself', () {
      final cat = _catalog([
        _day(1, 'inn', '1-1'),
        _day(2, 'inn', '2-2'),
        _day(3, 'house', '3-3'),
        _day(4, 'inn', '4-4'),
        _day(5, 'inn', '5-5'),
      ]);
      final m = landmarksByDay(_simplePlan(5), cat);
      expect(m.map((d, l) => MapEntry(d, l.map((x) => x.art).toList())), {
        1: ['inn'],
        3: ['house'],
        5: ['inn'],
      });
    });

    test('when the lead is a repeat, the second landmark takes its place', () {
      final cat = _catalog([
        _day(1, 'inn', '1-1'),
        _day(2, 'inn', '2-2', also: 'well'),
      ]);
      final m = landmarksByDay(_simplePlan(2), cat);
      expect(m[2]!.map((l) => l.art), ['well']);
    });
  });

  group('RoadGeometry', () {
    const g = RoadGeometry();
    test('the road climbs and passes through each stop', () {
      for (var n = 1; n < 6; n++) {
        final s = g.stop(n);
        final p = g.at(n.toDouble());
        expect((p.x - s.x).abs(), lessThan(1e-9));
        expect((p.y - s.y).abs(), lessThan(1e-9));
        expect(g.stop(n + 1).y, lessThan(s.y));
      }
    });
    test('mid-way points stay between the neighbouring stops vertically', () {
      final p = g.at(3.5);
      expect(p.y, lessThan(g.stop(3).y));
      expect(p.y, greaterThan(g.stop(4).y));
    });
  });
}
