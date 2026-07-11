import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';
import 'package:openbaptisthymnal/features/daily/domain/plan_generator.dart';

void main() {
  BibleBookInfo book(
    String code,
    int ordinal,
    List<int> chapterVerseCounts,
  ) =>
      BibleBookInfo(
        ordinal: ordinal,
        code: code,
        name: code,
        chapterVerseCounts: chapterVerseCounts,
      );

  group('Given a set of books and a day count', () {
    group('When a plan is generated', () {
      test('Then it has exactly the requested number of days', () {
        final days = generateVerseBalancedDays(
          books: [book('GEN', 1, List.filled(50, 30))],
          days: 10,
        );

        expect(days, hasLength(10));
        expect(days.first.dayIndex, 1, reason: 'dayIndex is 1-based');
        expect(days.last.dayIndex, 10);
      });

      test('Then every chapter is scheduled exactly once, in order', () {
        // The load-bearing invariant. A plan that drops Leviticus 12 or reads
        // it twice is broken in a way no amount of "looks about right" catches.
        final days = generateVerseBalancedDays(
          books: [
            book('GEN', 1, [10, 20, 30, 40]),
            book('EXO', 2, [15, 25, 35]),
          ],
          days: 3,
        );

        final scheduled = [
          for (final day in days)
            for (final passage in day.passages)
              for (var c = passage.start.chapter;
                  c <= passage.end.chapter;
                  c++)
                '${passage.start.book}.$c',
        ];

        expect(scheduled, [
          'GEN.1', 'GEN.2', 'GEN.3', 'GEN.4', //
          'EXO.1', 'EXO.2', 'EXO.3',
        ]);
      });

      test('Then no day is empty', () {
        // 12 chapters over 12 days: the reserve rule must hand each day one,
        // even though the verse targets would happily give day 1 several.
        final days = generateVerseBalancedDays(
          books: [book('GEN', 1, [100, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])],
          days: 12,
        );

        expect(days, hasLength(12));
        for (final day in days) {
          expect(day.passages, isNotEmpty, reason: 'day ${day.dayIndex}');
        }
      });
    });

    group('When a day spans a book boundary', () {
      test('Then it splits into one passage per book', () {
        // VerseRange cannot cross a book, so this is a correctness requirement,
        // not a formatting preference.
        final days = generateVerseBalancedDays(
          books: [
            book('MAL', 39, [10]),
            book('MAT', 40, [10]),
          ],
          days: 1,
        );

        expect(days.single.passages.map((p) => p.toString()).toList(), [
          'MAL.1.1-10',
          'MAT.1.1-10',
        ]);
      });
    });

    group('When consecutive chapters of one book fall on the same day', () {
      test('Then they merge into a single range', () {
        final days = generateVerseBalancedDays(
          books: [book('GEN', 1, [10, 20, 30])],
          days: 1,
        );

        expect(days.single.passages.single.toString(), 'GEN.1.1-3.30');
      });
    });

    group('When a passage is built', () {
      test('Then it covers the whole chapter, verse 1 to its last verse', () {
        final days = generateVerseBalancedDays(
          books: [book('PSA', 19, [6])],
          days: 1,
        );

        final passage = days.single.passages.single;
        expect(passage.start.verse, 1);
        expect(passage.end.verse, 6, reason: 'the chapter has 6 verses');
      });
    });
  });

  group('Given more days are requested than there are chapters', () {
    group('When a plan is generated', () {
      test('Then it throws rather than emitting an empty day', () {
        expect(
          () => generateVerseBalancedDays(
            books: [book('GEN', 1, [10, 20])],
            days: 5,
          ),
          throwsArgumentError,
        );
      });
    });
  });

  group('Given a day count below one', () {
    group('When a plan is generated', () {
      test('Then it throws', () {
        expect(
          () => generateVerseBalancedDays(
            books: [book('GEN', 1, [10])],
            days: 0,
          ),
          throwsArgumentError,
        );
      });
    });
  });

  group('Given chapters of wildly uneven length', () {
    group('When the plan is balanced', () {
      test('Then days even out by verses, not by chapter count', () {
        // The whole reason the generator weights by verse count. One 100-verse
        // chapter should occupy a day on its own, while ten 1-verse chapters
        // share one.
        final days = generateVerseBalancedDays(
          books: [
            book('AAA', 1, [100, 100]),
            book('BBB', 2, List.filled(10, 1)),
          ],
          days: 3,
        );

        // Day 1 and day 2 take one big chapter each; the ten tiny ones land
        // together rather than being spread one-per-day.
        expect(days[0].passages.single.toString(), 'AAA.1.1-100');
        expect(days[1].passages.single.toString(), 'AAA.2.1-100');
        expect(days[2].passages.single.toString(), 'BBB.1.1-10.1');
      });
    });
  });
}
