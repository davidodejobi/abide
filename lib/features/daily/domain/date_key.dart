/// A calendar day in the user's local timezone, formatted `YYYY-MM-DD`.
///
/// The streak is keyed on this string rather than on a timestamp. Comparing
/// date keys sidesteps DST entirely: "did they read yesterday" is a question
/// about the calendar, not about elapsed hours, and on the two days a year the
/// clock jumps, 24-hour arithmetic answers it wrong.
library;

/// Formats [date] as its local `YYYY-MM-DD` key.
String dayKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year.toString().padLeft(4, '0')}-$month-$day';
}

/// The key for the current local day. Pass [now] in tests; the production
/// callers use the default. Mirrors the clock convention in
/// `core/utils/time_greeting.dart`: a pure function, with the wall clock read
/// only at the very edge.
String todayKey([DateTime? now]) => dayKey(now ?? DateTime.now());

/// Parses a `YYYY-MM-DD` key back into a local midnight [DateTime].
/// Returns null if [key] is malformed or names a date that does not exist.
DateTime? dateFromKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return null;

  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;

  // DateTime silently rolls overflow forward (Feb 30 -> Mar 2), so a
  // round-trip is the only honest way to reject a date that never existed.
  final date = DateTime(year, month, day);
  if (date.month != month || date.day != day) return null;
  return date;
}

/// The calendar day before [date].
///
/// Deliberately NOT `subtract(const Duration(days: 1))`. A Duration is 24 fixed
/// hours, so on a DST spring-forward it lands at 23:00 the day before *that* --
/// silently skipping a day and breaking a streak the user never missed. Feeding
/// `day - 1` to the constructor is calendar arithmetic: Dart normalises the
/// underflow (day 0 of March becomes the last day of February), and it is right
/// across DST, month ends and leap years alike.
DateTime previousDay(DateTime date) =>
    DateTime(date.year, date.month, date.day - 1);

/// The calendar day after [date]. Same reasoning as [previousDay].
DateTime nextDay(DateTime date) =>
    DateTime(date.year, date.month, date.day + 1);

/// Whole calendar days between [a] and [b], regardless of order.
///
/// Projects both onto UTC midnight before subtracting. Taking `difference()` on
/// two *local* midnights spans 23 or 25 hours across a DST boundary, so
/// `inDays` truncates to 6 for what is plainly a 7-day gap -- which would
/// quietly resize the streak's grace window on exactly two weeks of the year.
int daysBetween(DateTime a, DateTime b) {
  final utcA = DateTime.utc(a.year, a.month, a.day);
  final utcB = DateTime.utc(b.year, b.month, b.day);
  return utcA.difference(utcB).inDays.abs();
}
