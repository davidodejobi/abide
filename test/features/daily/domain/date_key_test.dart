import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/daily/domain/date_key.dart';

void main() {
  group('Given a DateTime', () {
    group('When it is turned into a day key', () {
      test('Then it is zero-padded to YYYY-MM-DD', () {
        expect(dayKey(DateTime(2026, 1, 5)), '2026-01-05');
        expect(dayKey(DateTime(2026, 12, 31)), '2026-12-31');
      });

      test('Then the time of day is discarded', () {
        expect(dayKey(DateTime(2026, 1, 5, 0, 0)), '2026-01-05');
        expect(dayKey(DateTime(2026, 1, 5, 23, 59, 59)), '2026-01-05');
      });

      test('Then keys sort chronologically as plain strings', () {
        // The streak walk relies on this: it compares keys with compareTo
        // rather than parsing them back into dates.
        final keys = [
          dayKey(DateTime(2026, 2, 1)),
          dayKey(DateTime(2025, 12, 31)),
          dayKey(DateTime(2026, 1, 9)),
        ]..sort();
        expect(keys, ['2025-12-31', '2026-01-09', '2026-02-01']);
      });
    });
  });

  group('Given a day key string', () {
    group('When it is parsed back', () {
      test('Then it round-trips to the same key', () {
        expect(dayKey(dateFromKey('2026-01-05')!), '2026-01-05');
      });

      test('Then a malformed key is rejected rather than guessed at', () {
        expect(dateFromKey('2026-1-5'), isNotNull); // lenient on padding
        expect(dateFromKey('not-a-date'), isNull);
        expect(dateFromKey('2026-01'), isNull);
        expect(dateFromKey('2026-13-01'), isNull);
        expect(dateFromKey('2026-00-01'), isNull);
      });

      test('Then a date that never existed is rejected, not rolled forward',
          () {
        // DateTime(2026, 2, 30) silently becomes March 2. A key like this means
        // the data is corrupt, and quietly relocating it would hide that.
        expect(dateFromKey('2026-02-30'), isNull);
        expect(dateFromKey('2025-02-29'), isNull, reason: '2025 is not a leap');
      });

      test('Then a real leap day is accepted', () {
        expect(dateFromKey('2028-02-29'), isNotNull);
      });
    });
  });

  group('Given adjacent calendar days', () {
    group('When stepping backwards', () {
      test('Then it crosses a month boundary', () {
        expect(dayKey(previousDay(DateTime(2026, 3, 1))), '2026-02-28');
      });

      test('Then it crosses a year boundary', () {
        expect(dayKey(previousDay(DateTime(2026, 1, 1))), '2025-12-31');
      });

      test('Then it lands on the leap day in a leap year', () {
        expect(dayKey(previousDay(DateTime(2028, 3, 1))), '2028-02-29');
      });
    });

    group('When stepping forwards', () {
      test('Then it crosses a year boundary', () {
        expect(dayKey(nextDay(DateTime(2025, 12, 31))), '2026-01-01');
      });
    });
  });

  group('Given the date shown under the Today greeting', () {
    group('When it is formatted', () {
      test('Then it reads as a person would say it', () {
        // Replaced TimeGreeting.accent ("he gives his beloved sleep"), which
        // read as a fortune cookie under someone's name.
        expect(formatToday(DateTime(2026, 7, 11)), 'Saturday, 11 July');
        expect(formatToday(DateTime(2026, 1, 1)), 'Thursday, 1 January');
      });

      test('Then the weekday and month lookups do not run off their lists', () {
        // Monday is weekday 1 and December is month 12; an off-by-one in either
        // index throws a RangeError on exactly one day of the week or year.
        expect(formatToday(DateTime(2026, 12, 28)), 'Monday, 28 December');
        expect(formatToday(DateTime(2026, 12, 27)), 'Sunday, 27 December');
      });
    });
  });

  group('Given two calendar days', () {
    group('When the distance between them is measured', () {
      test('Then it counts whole days, in either direction', () {
        final a = DateTime(2026, 1, 1);
        final b = DateTime(2026, 1, 8);
        expect(daysBetween(a, b), 7);
        expect(daysBetween(b, a), 7, reason: 'order must not matter');
        expect(daysBetween(a, a), 0);
      });

      test('Then a week measured across a DST change is still 7 days', () {
        // The reason daysBetween projects onto UTC instead of subtracting two
        // local midnights: in a DST zone that week is 23 or 25 hours long, and
        // Duration.inDays would truncate it to 6 -- silently shrinking the
        // streak's grace window on exactly the weeks the clock moves.
        // (Europe/London springs forward on 2026-03-29.)
        expect(daysBetween(DateTime(2026, 3, 25), DateTime(2026, 4, 1)), 7);
        expect(daysBetween(DateTime(2026, 10, 22), DateTime(2026, 10, 29)), 7);
      });

      test('Then it spans a month boundary correctly', () {
        expect(daysBetween(DateTime(2026, 2, 26), DateTime(2026, 3, 5)), 7);
      });
    });
  });
}
