import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/daily/domain/date_key.dart';
import 'package:openbaptisthymnal/features/daily/domain/streak.dart';

void main() {
  // Fixed anchor. computeStreak never reads the clock, which is the whole point
  // -- these tests would be flaky at midnight otherwise.
  const today = '2026-01-15';
  final todayDate = DateTime(2026, 1, 15);

  /// The keys for [count] consecutive days ending [endingDaysAgo] days back.
  Set<String> daysEnding(int endingDaysAgo, int count) {
    final keys = <String>{};
    var cursor = todayDate;
    for (var i = 0; i < endingDaysAgo; i++) {
      cursor = previousDay(cursor);
    }
    for (var i = 0; i < count; i++) {
      keys.add(dayKey(cursor));
      cursor = previousDay(cursor);
    }
    return keys;
  }

  group('Given the user has never completed a day', () {
    group('When the streak is computed', () {
      test('Then it is zero and today is not marked done', () {
        final result = computeStreak(const {}, todayKey: today);

        expect(result.current, 0);
        expect(result.completedToday, isFalse);
        expect(result.isActive, isFalse);
        expect(result.graceDaysUsed, 0);
      });
    });
  });

  group('Given an unbroken run of completed days', () {
    group('When the run includes today', () {
      test('Then every day counts', () {
        final result = computeStreak(daysEnding(0, 5), todayKey: today);

        expect(result.current, 5);
        expect(result.completedToday, isTrue);
        expect(result.graceDaysUsed, 0);
      });
    });

    group('When today has not been read yet', () {
      test('Then the run survives, because today is not a missed day', () {
        // The user opens the app at 9am with a 5-day run. Counting the day they
        // are standing in as missed would punish them for showing up early.
        final result = computeStreak(daysEnding(1, 5), todayKey: today);

        expect(result.current, 5);
        expect(result.completedToday, isFalse);
        expect(result.isActive, isTrue);
        expect(result.graceDaysUsed, 0);
      });
    });
  });

  group('Given a single missed day inside the run', () {
    group('When grace is allowed', () {
      test('Then the run survives but the skipped day is not credited', () {
        // Read today, missed yesterday, read the 5 before that.
        final completed = {today, ...daysEnding(2, 5)};

        final result = computeStreak(completed, todayKey: today);

        expect(result.current, 6, reason: '1 + 5 completed; the gap is not one');
        expect(result.graceDaysUsed, 1);
      });
    });

    group('When the user is in strict mode', () {
      test('Then the run ends at the gap', () {
        final completed = {today, ...daysEnding(2, 5)};

        final result =
            computeStreak(completed, todayKey: today, graceDaysPerWeek: 0);

        expect(result.current, 1, reason: 'only today; yesterday broke it');
        expect(result.graceDaysUsed, 0);
      });
    });
  });

  group('Given two missed days in a row', () {
    group('When the streak is computed', () {
      test('Then the run breaks -- one grace cannot cover both', () {
        // Read today; missed the two days before it.
        final completed = {today, ...daysEnding(3, 5)};

        final result = computeStreak(completed, todayKey: today);

        expect(result.current, 1, reason: 'the second miss is unforgivable');
      });
    });
  });

  group('Given the grace window is exactly one week wide', () {
    // This is the line that defines "one rest day per week", and it is where a
    // < / <= slip would hide. Two misses, and only the distance between them
    // changes.
    group('When a second miss falls 6 days after the first', () {
      test('Then it is inside the window and the run breaks', () {
        final completed = {
          today, //            day 0   read
          //                   day 1   MISSED -> forgiven
          ...daysEnding(2, 5), // days 2-6  read
          //                   day 7   MISSED -> only 6 days after day 1
          ...daysEnding(8, 5), // days 8-12 read, but never reached
        };

        final result = computeStreak(completed, todayKey: today);

        expect(
          result.current,
          6,
          reason: 'today + days 2-6; the run stops at the day-7 miss because '
              'it falls inside the day-1 grace window',
        );
        expect(result.graceDaysUsed, 1);
      });
    });

    group('When a second miss falls exactly 7 days after the first', () {
      test('Then it opens a fresh window and is forgiven too', () {
        final completed = {
          today, //            day 0   read
          //                   day 1   MISSED -> forgiven
          ...daysEnding(2, 6), // days 2-7  read
          //                   day 8   MISSED -> exactly 7 days after day 1,
          //                                     so a fresh window: forgiven
          ...daysEnding(9, 5), // days 9-13 read
        };

        final result = computeStreak(completed, todayKey: today);

        expect(
          result.current,
          12,
          reason: '1 (today) + 6 + 5 completed; both misses forgiven',
        );
        expect(result.graceDaysUsed, 2);
      });
    });
  });

  // Deliberately no "a day marked twice counts once" test here: the input is a
  // Set, so a duplicate day cannot exist to begin with, and asserting it would
  // only be testing Dart. Double-marking is a real risk one layer down, where
  // the dateKey primary key makes the write idempotent -- it is tested there.

  group('Given a run crossing a month, year and leap-day boundary', () {
    group('When the streak is computed', () {
      test('Then calendar arithmetic carries it across', () {
        // 2028-03-01 back through the leap day, February, and into January.
        final completed = <String>{};
        var cursor = DateTime(2028, 3, 1);
        for (var i = 0; i < 70; i++) {
          completed.add(dayKey(cursor));
          cursor = previousDay(cursor);
        }

        final result = computeStreak(completed, todayKey: '2028-03-01');

        expect(result.current, 70);
        expect(completed, contains('2028-02-29'), reason: 'leap day included');
        expect(completed, contains('2027-12-31'), reason: 'crossed the year');
      });
    });
  });

  group('Given a long-abandoned history', () {
    group('When the user has not read in months', () {
      test('Then the streak is zero and the walk still terminates', () {
        final result =
            computeStreak({'2020-01-01', '2020-01-02'}, todayKey: today);

        expect(result.current, 0);
        expect(result.graceDaysUsed, 0, reason: 'no run, so nothing forgiven');
      });
    });
  });

  group('Given a malformed today key', () {
    group('When the streak is computed', () {
      test('Then it throws rather than silently returning zero', () {
        // A zero streak would look exactly like "the user lapsed" and would be
        // shown to them as such. Better to fail loudly.
        expect(
          () => computeStreak(const {}, todayKey: 'yesterday'),
          throwsArgumentError,
        );
      });
    });
  });
}
