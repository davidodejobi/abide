import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/bible/domain/verse_ref.dart';
import 'package:openbaptisthymnal/features/daily/domain/plan_progress.dart';
import 'package:openbaptisthymnal/features/daily/domain/reading_plan.dart';

void main() {
  PlanDay day(int index, List<String> refs) => PlanDay(
        dayIndex: index,
        passages: [for (final r in refs) VerseRange.tryParse(r)!],
      );

  group('Given a plan the reader is partway through', () {
    group('When the next day is asked for', () {
      test('Then it is the first day not yet read', () {
        expect(nextPlanDayIndex({1, 2, 3}, 365), 4);
      });

      test('Then a fresh plan starts at day 1, not day 0', () {
        expect(nextPlanDayIndex(const {}, 365), 1);
      });

      test('Then a gap is filled before moving on', () {
        // Progress-driven, not calendar-driven. Someone who read days 1, 2 and 4
        // has not lost day 3 -- they are pointed back at it. A calendar-driven
        // plan would silently decide they are just never going to read it.
        expect(nextPlanDayIndex({1, 2, 4}, 365), 3);
      });

      test('Then reading ahead does not skip the days behind', () {
        expect(nextPlanDayIndex({5, 6, 7}, 365), 1);
      });
    });

    group('When every day is done', () {
      test('Then it returns null rather than a day past the end', () {
        // The finished state. Returning dayCount + 1 here would send the card
        // looking for a passage that does not exist.
        expect(nextPlanDayIndex({1, 2, 3}, 3), isNull);
      });
    });
  });

  group('Given a plan day spanning several chapters', () {
    group('When the opening reference is built for openBibleLink', () {
      test('Then it is the START verse only, never the full range', () {
        // The bug this exists to prevent: BibleLinkResolver sets
        // `chapter = start.chapter` but `hiTo = range.end.verse`, and
        // BibleNavigationTarget has no end-chapter field. So passing the whole
        // range 'GEN.1.1-4.26' opens Genesis 1 and flashes "verses 1 to 26" OF
        // CHAPTER 1 -- not an error, not a crash, just a highlight that means
        // nothing, on most days of most plans.
        final today = day(1, ['GEN.1.1-4.26']);

        expect(openingRefFor(today), 'GEN.1.1');
        expect(
          openingRefFor(today),
          isNot(contains('-')),
          reason: 'a range would be silently mis-highlighted by the resolver',
        );
      });

      test('Then a day crossing a book boundary opens at the first book', () {
        final today = day(58, ['MAL.4.1-6', 'MAT.1.1-25']);

        expect(openingRefFor(today), 'MAL.4.1');
      });

      test('Then a single-chapter day still opens at verse 1', () {
        expect(openingRefFor(day(188, ['PSA.120.1-7'])), 'PSA.120.1');
      });
    });
  });
}
