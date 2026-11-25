import 'date_key.dart';
import 'reading_plan.dart';

/// Calendar rules for a plan with a fixed start (`startsOn`, "MM-DD"), such as
/// the Bible in a Year: everyone begins on 1 January and day N is the Nth day
/// of that run. Pure, so the clock is always passed in.
///
/// Plans with no `startsOn` are open any time and none of this applies.
class PlanSchedule {
  const PlanSchedule(this.plan);

  final ReadingPlan plan;

  bool get isFixed => _parts != null;

  (int, int)? get _parts {
    final raw = plan.startsOn;
    if (raw == null) return null;
    final p = raw.split('-');
    if (p.length != 2) return null;
    final m = int.tryParse(p[0]);
    final d = int.tryParse(p[1]);
    if (m == null || d == null) return null;
    // Round-trip in a non-leap year: rejects 02-30, and 02-29 too, which
    // would drift between years. Start dates are not leap days.
    final probe = DateTime(2001, m, d);
    return (probe.month == m && probe.day == d) ? (m, d) : null;
  }

  /// First day anyone could start, or null when the plan is always open.
  DateTime? get opensOn {
    final y = plan.firstRunYear;
    final p = _parts;
    if (y == null || p == null) return null;
    return DateTime(y, p.$1, p.$2);
  }

  /// Not startable yet. Locks only before the first run; after that the plan
  /// is open all year (late joiners catch up) and rolls on each start date.
  bool isLocked(DateTime today) {
    final o = opensOn;
    return o != null && DateTime(today.year, today.month, today.day).isBefore(o);
  }

  /// Whole days until [opensOn], 0 once open.
  int daysToGo(DateTime today) {
    final o = opensOn;
    return (o == null || !isLocked(today)) ? 0 : daysBetween(today, o);
  }

  /// "1 January", for the locked label. Empty for a plan with no fixed start.
  String get startLabel {
    final p = _parts;
    return p == null ? '' : '${p.$2} ${_months[p.$1 - 1]}';
  }

  /// Start of the run [date] belongs to: the latest start date on or before it.
  DateTime cycleStart(DateTime date) {
    final p = _parts!;
    final day = DateTime(date.year, date.month, date.day);
    final thisYear = DateTime(date.year, p.$1, p.$2);
    return thisYear.isAfter(day) ? DateTime(date.year - 1, p.$1, p.$2) : thisYear;
  }

  /// The calendar day of the run for [date], 1-based. Clamped to the plan, so
  /// day 366 of a leap year reads the final day rather than falling off.
  int calendarDay(DateTime date) {
    final n = daysBetween(date, cycleStart(date)) + 1;
    return n.clamp(1, plan.dayCount);
  }

  /// Whether [startDateKey] (when someone began) belongs to the run [today] is
  /// in. False once the year has rolled: last year's progress is a finished
  /// run, and this year's starts fresh.
  bool isCurrentRun(String startDateKey, DateTime today) {
    final started = dateFromKey(startDateKey);
    return started != null && cycleStart(started) == cycleStart(today);
  }

  /// The day to read next for someone who began on [startDateKey].
  ///
  /// Late joiners begin at the calendar day they joined, not day 1, so on
  /// 15 Jan they read day 15 with the days before it left as catch-up. Within
  /// the run it stays progress-driven (first unread day from there), and once
  /// everything ahead is read the remaining catch-up days come back round.
  /// Null when every day is done.
  int? nextDay(Set<int> done, String startDateKey) {
    final started = dateFromKey(startDateKey);
    final floor = started == null ? 1 : calendarDay(started);
    for (var d = floor; d <= plan.dayCount; d++) {
      if (!done.contains(d)) return d;
    }
    for (var d = 1; d < floor; d++) {
      if (!done.contains(d)) return d;
    }
    return null;
  }

  /// Days before today's calendar day still unread. Offered, never a debt.
  int catchUpCount(Set<int> done, DateTime today) {
    var n = 0;
    for (var d = 1; d < calendarDay(today); d++) {
      if (!done.contains(d)) n++;
    }
    return n;
  }
}

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
