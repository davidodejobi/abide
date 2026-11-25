import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/bible/domain/verse_ref.dart';
import 'package:openbaptisthymnal/features/daily/domain/road_geometry.dart';
import 'package:openbaptisthymnal/features/daily/domain/road_landmarks.dart';
import 'package:openbaptisthymnal/features/daily/domain/reading_plan.dart';

PlanDay _day(int i, List<String> refs) => PlanDay(
      dayIndex: i,
      passages: [for (final r in refs) VerseRange.tryParse(r)!],
    );

Landmark _lm(String id, String book, int from, int to,
        {bool hasArt = true, String? art}) =>
    Landmark(
      id: id,
      book: book,
      fromChapter: from,
      toChapter: to,
      title: id,
      short: id,
      ref: id,
      art: hasArt ? (art ?? id) : null,
    );

void main() {
  final plan = ReadingPlan(id: 'p', title: '', description: '', days: [
    _day(1, ['GEN.1.1-3.24']),
    _day(2, ['GEN.4.1-5.32']),
    _day(3, ['GEN.6.1-9.29']),
    _day(4, ['MAL.4.1-6', 'MAT.1.1-25']),
  ]);

  test('a landmark lands on the first day that touches its chapters', () {
    final m = landmarksByDay(plan, [
      _lm('garden', 'GEN', 1, 2),
      _lm('ark', 'GEN', 6, 9),
      _lm('manger', 'MAT', 1, 1),
    ]);
    expect(m.map((d, l) => MapEntry(d, l.id)), {1: 'garden', 3: 'ark', 4: 'manger'});
  });

  test('landmarks without art are not placed, and one landmark never repeats', () {
    final m = landmarksByDay(plan, [
      _lm('noart', 'GEN', 1, 1, hasArt: false),
      _lm('garden', 'GEN', 1, 5),
    ]);
    expect(m.length, 1);
    expect(m[1]!.id, 'garden');
  });

  test('one landmark per day: the second waits for a later day or is dropped', () {
    final m = landmarksByDay(plan, [
      _lm('a', 'GEN', 1, 1),
      _lm('b', 'GEN', 2, 3),
    ]);
    expect(m[1]!.id, 'a');
    // b touches day 1 too but loses it; it moves to day 2, which is free.
    expect(m[2]!.id, 'b');
    expect(m.length, 2);
  });

  test('a displaced landmark moves one day only, then is dropped', () {
    final m = landmarksByDay(plan, [
      _lm('a', 'GEN', 1, 1),
      _lm('b', 'GEN', 1, 1),
      _lm('c', 'GEN', 1, 1),
    ]);
    expect(m.values.map((l) => l.id), ['a', 'b']);
  });

  test('the same art is not repeated within a few days', () {
    final m = landmarksByDay(plan, [
      _lm('sinai', 'GEN', 1, 1, art: 'sinai'),
      _lm('tablets', 'GEN', 4, 4, art: 'sinai'),
    ]);
    expect(m.values.map((l) => l.id), ['sinai']);
  });

  test('parseLandmarks reads the bundled compact format', () {
    final l = parseLandmarks(
        '[{"id":"g","book":"GEN","from":1,"to":2,"title":"T","short":"S","ref":"Genesis 1:1","art":"garden"}]');
    expect(l.single.art, 'garden');
    expect(l.single.toChapter, 2);
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
