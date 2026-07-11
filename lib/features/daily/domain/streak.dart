import 'date_key.dart';

/// The streak, derived from the set of days the user actually completed.
///
/// Nothing here is stored. A stored counter is a lie waiting to happen: it
/// drifts on clock skew, a timezone move, or a write that failed halfway, and
/// once it is wrong it stays wrong with no way to notice. Storing the *facts*
/// (which days were completed) and deriving the *number* means the streak can
/// always be recomputed from scratch and can never disagree with itself.
class StreakResult {
  const StreakResult({
    required this.current,
    required this.completedToday,
    required this.graceDaysUsed,
  });

  /// Days in the current unbroken run, counting only days actually completed.
  /// A forgiven day (see [computeStreak]) keeps the run alive but does not
  /// inflate the count -- you cannot earn a day by skipping it.
  final int current;

  /// Whether today is already done. Drives "read today" vs "come back tomorrow"
  /// -- and note [current] can be non-zero while this is false, because a day
  /// still in progress is not yet a missed day.
  final bool completedToday;

  /// How many missed days the grace rule forgave inside the current run.
  /// Surfaced so the UI can be honest ("1 rest day used") instead of pretending
  /// the run was perfect.
  final int graceDaysUsed;

  bool get isActive => current > 0;
}

/// Computes the streak ending at [todayKey] from the days in [completedDayKeys]
/// (each a `YYYY-MM-DD` key -- see `date_key.dart`).
///
/// **Today is never a miss.** The walk starts at today if it is done, and at
/// yesterday otherwise. Someone opening the app at 9am has not broken anything;
/// counting the day they are standing in as missed would punish them for being
/// early.
///
/// **Grace.** At most [graceDaysPerWeek] missed days may be forgiven in any
/// 7-day window. This is a deliberate departure from the Duolingo model: the
/// audience is people building a devotional habit, and guilt is the wrong lever
/// -- a single bad week should not erase a year. Two misses in a row still
/// break the run (the second falls inside the first's window), so the streak
/// keeps meaning something. Pass 0 for strict mode.
StreakResult computeStreak(
  Set<String> completedDayKeys, {
  required String todayKey,
  int graceDaysPerWeek = 1,
}) {
  final today = dateFromKey(todayKey);
  if (today == null) {
    throw ArgumentError.value(todayKey, 'todayKey', 'not a YYYY-MM-DD key');
  }

  final completedToday = completedDayKeys.contains(todayKey);

  // Bounds the walk. Without this a generous grace rule could march backwards
  // through empty calendar forever; there is nothing to find below the earliest
  // day the user ever completed.
  final earliest = completedDayKeys.isEmpty
      ? null
      : completedDayKeys.reduce((a, b) => a.compareTo(b) < 0 ? a : b);
  if (earliest == null) {
    return const StreakResult(
      current: 0,
      completedToday: false,
      graceDaysUsed: 0,
    );
  }

  var cursor = completedToday ? today : previousDay(today);
  var current = 0;
  final forgiven = <DateTime>[];

  while (dayKey(cursor).compareTo(earliest) >= 0) {
    if (completedDayKeys.contains(dayKey(cursor))) {
      current++;
    } else {
      // Forgive only if no other forgiven day sits within the same 7-day
      // window. `< 7` (not `<= 7`) is what makes it once *per week*: a miss
      // exactly 7 days after a forgiven one opens a fresh window, 6 days does
      // not. daysBetween (not Duration) so DST cannot shrink the window.
      final inWindow =
          forgiven.where((day) => daysBetween(cursor, day) < 7).length;
      if (inWindow >= graceDaysPerWeek) break;
      forgiven.add(cursor);
    }
    cursor = previousDay(cursor);
  }

  return StreakResult(
    current: current,
    completedToday: completedToday,
    // With no completed day there is no run, so nothing was rested from -- any
    // day the walk forgave on the way down is an artifact of the walk, not a
    // rest day the user took.
    graceDaysUsed: current == 0 ? 0 : forgiven.length,
  );
}
