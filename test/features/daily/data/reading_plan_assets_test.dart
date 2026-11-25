import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/bible/domain/verse_ref.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';
import 'package:openbaptisthymnal/features/daily/domain/plan_generator.dart';
import 'package:openbaptisthymnal/features/daily/domain/reading_plan.dart';

/// Validates the reading plans **as they ship**.
///
/// Deliberately loaded through `rootBundle`, not read off disk and not
/// regenerated in-memory. Two different things can go wrong and only this
/// catches both:
///
///  - the JSON is committed but never declared in pubspec, so it is missing
///    from the bundle and the app throws on a device but not in a unit test;
///  - the committed JSON drifts from what the generator would now produce, so a
///    test that regenerates its own input passes green while the app ships
///    stale data.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const planIds = ['bible-in-a-year', 'nt-90', 'psalms-30'];

  late Map<String, BibleBookInfo> booksByCode;

  setUpAll(() async {
    final raw = await rootBundle.loadString('assets/bible/en-kjv/manifest.json');
    final manifest =
        BibleManifest.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    booksByCode = {for (final b in manifest.books) b.code: b};
  });

  Future<ReadingPlan> loadPlan(String id) async {
    final raw = await rootBundle.loadString('assets/plans/$id.json');
    return ReadingPlan.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  group('Given the reading plans are bundled assets', () {
    for (final id in planIds) {
      group('When $id is loaded from the asset bundle', () {
        test('Then it parses, and every passage is a valid VerseRange', () {
          // ReadingPlan.fromJson throws on a passage VerseRange cannot parse,
          // so reaching the assertions is itself the parse test.
          expectLater(loadPlan(id), completes);
        });

        test('Then every passage resolves inside the real Bible', () async {
          final plan = await loadPlan(id);

          for (final day in plan.days) {
            expect(day.passages, isNotEmpty, reason: '$id day ${day.dayIndex}');

            for (final passage in day.passages) {
              final where = '$id day ${day.dayIndex}: $passage';

              final book = booksByCode[passage.start.book];
              expect(book, isNotNull, reason: '$where -- unknown book');

              // The test that stops a plan day pointing at Genesis 51.
              expect(
                passage.end.chapter,
                lessThanOrEqualTo(book!.chapterCount),
                reason: '$where -- book has ${book.chapterCount} chapters',
              );
              expect(
                passage.end.verse,
                lessThanOrEqualTo(
                  book.chapterVerseCounts[passage.end.chapter - 1],
                ),
                reason: '$where -- chapter is shorter than that',
              );
              expect(passage.start.verse, 1, reason: '$where -- whole chapters');
            }
          }
        });

        test('Then day indexes run 1..n with no gaps', () async {
          final plan = await loadPlan(id);

          expect(
            plan.days.map((d) => d.dayIndex),
            List.generate(plan.dayCount, (i) => i + 1),
            reason: 'dayIndex is half of the <planId>:<dayIndex> progress key; '
                'a gap or an off-by-one silently opens the wrong reading',
          );
        });
      });
    }
  });

  group('Given the Bible-in-a-year plan', () {
    group('When its coverage is checked', () {
      test('Then it schedules all 1189 chapters exactly once, in order',
          () async {
        // The invariant that matters: a year-long plan that quietly drops a
        // chapter, or reads one twice, is broken in a way no spot-check finds.
        final plan = await loadPlan('bible-in-a-year');

        final scheduled = [
          for (final day in plan.days)
            for (final passage in day.passages)
              for (var c = passage.start.chapter;
                  c <= passage.end.chapter;
                  c++)
                '${passage.start.book}.$c',
        ];

        final expected = [
          for (final book in booksByCode.values)
            for (var c = 1; c <= book.chapterCount; c++) '${book.code}.$c',
        ];

        expect(plan.dayCount, 365);
        expect(scheduled, expected);
        expect(scheduled, hasLength(1189));
      });

      test('Then the daily load is steady rather than lumpy', () async {
        final plan = await loadPlan('bible-in-a-year');

        int versesIn(PlanDay day) => day.passages.fold<int>(
              0,
              (sum, p) => sum + _versesInRange(p, booksByCode),
            );

        final perDay = plan.days.map(versesIn).toList();
        final mean = perDay.reduce((a, b) => a + b) / perDay.length;

        expect(mean, closeTo(31102 / 365, 1), reason: '~85 verses a day');

        // A soft, aggregate bound on purpose. Psalm 119 alone is 176 verses and
        // cannot be split, so a tight per-day band would fail a *correct* plan.
        // What we actually care about is that the typical day is close to the
        // target, not that no day is ever long.
        final deviation =
            perDay.map((v) => (v - mean).abs()).reduce((a, b) => a + b) /
                perDay.length;
        expect(
          deviation,
          lessThan(20),
          reason: 'mean absolute deviation, in verses',
        );
      });
    });
  });

  group('Given the plans are generated, not hand-written', () {
    group('When the generator is re-run against the same manifest', () {
      test('Then it reproduces the committed asset exactly', () async {
        // Closes the drift loop, same idea as the drift_schemas guard test:
        // change the generator (or hand-edit the JSON) without regenerating and
        // this goes red. Without it, the algorithm and the asset people
        // actually read can quietly disagree forever.
        final plan = await loadPlan('bible-in-a-year');

        final regenerated = generateVerseBalancedDays(
          books: booksByCode.values.toList(growable: false),
          days: 365,
        );

        expect(
          regenerated.map((d) => d.passages.map((p) => p.toString()).toList()),
          plan.days.map((d) => d.passages.map((p) => p.toString()).toList()),
          reason: 'assets/plans is stale -- run: '
              'dart run tool/gen_reading_plans.dart',
        );
      });
    });
  });

  group('Given the New Testament plan', () {
    group('When its coverage is checked', () {
      test('Then it starts at Matthew, ends at Revelation, and skips the OT',
          () async {
        final plan = await loadPlan('nt-90');

        final books = {
          for (final day in plan.days)
            for (final passage in day.passages) passage.start.book,
        };

        expect(plan.dayCount, 90);
        expect(plan.days.first.passages.first.start.book, 'MAT');
        expect(plan.days.last.passages.last.end.book, 'REV');
        expect(books, hasLength(27));
        expect(books, isNot(contains('GEN')));
      });
    });
  });

  group('Given the Psalms plan', () {
    group('When its coverage is checked', () {
      test('Then it covers all 150 psalms in 30 days', () async {
        final plan = await loadPlan('psalms-30');

        final psalms = <int>[];
        for (final day in plan.days) {
          for (final passage in day.passages) {
            expect(passage.start.book, 'PSA');
            for (var c = passage.start.chapter;
                c <= passage.end.chapter;
                c++) {
              psalms.add(c);
            }
          }
        }

        expect(plan.dayCount, 30);
        expect(psalms, List.generate(150, (i) => i + 1));
      });
    });
  });
}

/// Total verses a passage covers, per the manifest.
int _versesInRange(VerseRange passage, Map<String, BibleBookInfo> booksByCode) {
  final book = booksByCode[passage.start.book]!;
  var total = 0;
  for (var c = passage.start.chapter; c <= passage.end.chapter; c++) {
    total += book.chapterVerseCounts[c - 1];
  }
  return total;
}
