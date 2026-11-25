import 'dart:convert';
import 'dart:io';

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
    expect(m.map((d, l) => MapEntry(d, l.single.id)),
        {1: 'garden', 3: 'ark', 4: 'manger'});
  });

  test('landmarks without art are not placed, and one landmark never repeats',
      () {
    final m = landmarksByDay(plan, [
      _lm('noart', 'GEN', 1, 1, hasArt: false),
      _lm('garden', 'GEN', 1, 5),
    ]);
    expect(m.length, 1);
    expect(m[1]!.single.id, 'garden');
  });

  test('two landmarks can share a day, own matches first', () {
    final m = landmarksByDay(plan, [
      _lm('a', 'GEN', 1, 1),
      _lm('b', 'GEN', 1, 1),
    ]);
    expect(m[1]!.map((l) => l.id), ['a', 'b']);
  });

  test("a day's own match beats a displaced one, which never cascades", () {
    // Day 1 has three own matches (c is displaced); day 2 has two own, so c
    // finds no slot and is dropped, not pushed on to day 3.
    final m = landmarksByDay(plan, [
      _lm('a', 'GEN', 1, 1),
      _lm('b', 'GEN', 1, 1),
      _lm('c', 'GEN', 1, 1),
      _lm('d', 'GEN', 4, 5),
      _lm('e', 'GEN', 4, 5),
    ]);
    expect(m[1]!.map((l) => l.id), ['a', 'b']);
    expect(m[2]!.map((l) => l.id), ['d', 'e']);
    expect(m.containsKey(3), isFalse);
  });

  test('a displaced landmark takes the next day when it has a free slot', () {
    final m = landmarksByDay(plan, [
      _lm('a', 'GEN', 1, 1),
      _lm('b', 'GEN', 1, 1),
      _lm('c', 'GEN', 1, 1),
      _lm('d', 'GEN', 4, 5),
    ]);
    expect(m[2]!.map((l) => l.id), ['d', 'c']);
  });

  group('the bundled plans with the real landmarks', () {
    final all = parseLandmarks(
        File('assets/images/road/landmarks.json').readAsStringSync());
    for (final id in ['nt-90', 'bible-in-a-year', 'psalms-30']) {
      test('$id: every landmark stands on its own day or the one after', () {
        final plan = ReadingPlan.fromJson(
            jsonDecode(File('assets/plans/$id.json').readAsStringSync())
                as Map<String, dynamic>);
        final m = landmarksByDay(plan, all, placeArtless: true);
        bool touches(Landmark lm, int day) =>
            plan.dayAt(day)!.passages.any((p) =>
                p.start.book == lm.book &&
                p.start.chapter <= lm.toChapter &&
                p.end.chapter >= lm.fromChapter);
        final seen = <String>{};
        m.forEach((day, lms) {
          expect(lms.length, lessThanOrEqualTo(2));
          var carried = false;
          for (final lm in lms) {
            expect(seen.add(lm.id), isTrue, reason: '${lm.id} placed twice');
            final own = touches(lm, day);
            // Own matches come first; a carried one touches the day before
            // and never follows another carried one.
            if (!own) {
              expect(day > 1 && touches(lm, day - 1), isTrue,
                  reason: '${lm.id} drifted onto day $day');
              expect(carried, isFalse);
              carried = true;
            } else {
              expect(carried, isFalse, reason: 'own after carried on $day');
            }
          }
        });
      });
    }

    test('the last day shows both Revelation endings, and nt-90 keeps the nets',
        () {
      ReadingPlan load(String id) => ReadingPlan.fromJson(
          jsonDecode(File('assets/plans/$id.json').readAsStringSync())
              as Map<String, dynamic>);
      Iterable<String> ids(ReadingPlan p) =>
          landmarksByDay(p, all, placeArtless: true)
              .values
              .expand((l) => l)
              .map((l) => l.id);
      expect(ids(load('bible-in-a-year')),
          containsAll(['rev-new-jerusalem', 'rev-river-tree']));
      expect(ids(load('nt-90')), contains('mat-nets'));
    });

    test('nt-90: the Sermon on the Mount stands on the day that reads it', () {
      final plan = ReadingPlan.fromJson(
          jsonDecode(File('assets/plans/nt-90.json').readAsStringSync())
              as Map<String, dynamic>);
      final m = landmarksByDay(plan, all, placeArtless: true);
      final day = plan.days
          .firstWhere((d) => d.passages.any((p) =>
              p.start.book == 'MAT' &&
              p.start.chapter <= 5 &&
              p.end.chapter >= 5))
          .dayIndex;
      expect(m[day]!.map((l) => l.id), contains('mat-sermon'));
    });
  });

  test('the same art is not repeated within a few days', () {
    final m = landmarksByDay(plan, [
      _lm('sinai', 'GEN', 1, 1, art: 'sinai'),
      _lm('tablets', 'GEN', 4, 4, art: 'sinai'),
    ]);
    expect(m.values.expand((l) => l).map((l) => l.id), ['sinai']);
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
