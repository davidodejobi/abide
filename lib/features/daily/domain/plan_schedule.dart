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
    return o != null &&
        DateTime(today.year, today.month, today.day).isBefore(o);
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
    return thisYear.isAfter(day)
        ? DateTime(date.year - 1, p.$1, p.$2)
        : thisYear;
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

  /// Subscribed before the plan was anchored (before [opensOn]): these people
  /// already walk it at their own pace, so they keep that. No lock, no roll.
  bool isLegacy(String startDateKey) {
    final o = opensOn;
    final started = dateFromKey(startDateKey);
    return o != null && started != null && started.isBefore(o);
  }

  /// Which run and which progress bucket someone belongs to. [startDateKey] is
  /// null when they never subscribed. Anchored progress is stored per run year
  /// (`plan@2027`), so a new year starts clean and the old run stays in
  /// history, untouched.
  PlanRun runFor(String? startDateKey, DateTime today) {
    if (!isFixed) {
      return PlanRun(
          progressId: plan.id,
          anchored: false,
          joined: startDateKey != null,
          calendarDay: 0);
    }
    if (startDateKey != null && isLegacy(startDateKey)) {
      return PlanRun(
          progressId: plan.id, anchored: false, joined: true, calendarDay: 0);
    }
    return PlanRun(
      progressId: '${plan.id}@${cycleStart(today).year}',
      anchored: true,
      joined: startDateKey != null && isCurrentRun(startDateKey, today),
      calendarDay: calendarDay(today),
    );
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

/// Where someone stands on a plan, see [PlanSchedule.runFor].
class PlanRun {
  const PlanRun({
    required this.progressId,
    required this.anchored,
    required this.joined,
    required this.calendarDay,
  });

  /// The key their progress rows are stored under.
  final String progressId;

  /// Today's reading is the calendar day, not the next unread one.
  final bool anchored;

  /// Subscribed to the run that is current today.
  final bool joined;

  /// Today's day of the run; 0 when not anchored.
  final int calendarDay;
}

enum DayStatus { done, catchUp, today, ahead }

/// One status source for an anchored plan's road, stop sheets, screen-reader
/// labels and days list: read is done, unread past is catch-up, today is
/// current, the rest is ahead. Never "everything before today is done".
class PlanDayStatuses {
  const PlanDayStatuses({required this.done, required this.today});

  final Set<int> done;

  /// Today's calendar day.
  final int today;

  DayStatus of(int day) => done.contains(day)
      ? DayStatus.done
      : day < today
          ? DayStatus.catchUp
          : day == today
              ? DayStatus.today
              : DayStatus.ahead;

  @override
  bool operator ==(Object other) =>
      other is PlanDayStatuses &&
      other.today == today &&
      other.done.length == done.length &&
      other.done.containsAll(done);

  @override
  int get hashCode => Object.hash(today, done.length);
}
