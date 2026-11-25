import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/daily/domain/plan_schedule.dart';
import 'package:openbaptisthymnal/features/daily/domain/reading_plan.dart';

ReadingPlan _plan({String? startsOn = '01-01', int? firstRunYear = 2027}) =>
    ReadingPlan(
      id: 'year',
      title: 'Year',
      description: '',
      days: [
        for (var i = 1; i <= 365; i++) PlanDay(dayIndex: i, passages: const []),
      ],
      startsOn: startsOn,
      firstRunYear: firstRunYear,
    );

void main() {
  final s = PlanSchedule(_plan());

  test('locked before 1 Jan 2027, with a countdown', () {
    expect(s.isLocked(DateTime(2026, 11, 25)), isTrue);
    expect(s.daysToGo(DateTime(2026, 11, 25)), 37);
    expect(s.isLocked(DateTime(2026, 12, 31, 23, 59)), isTrue);
    expect(s.daysToGo(DateTime(2026, 12, 31)), 1);
    expect(s.startLabel, '1 January');
  });

  test('opens on 1 Jan, everyone on day 1', () {
    final day = DateTime(2027, 1, 1);
    expect(s.isLocked(day), isFalse);
    expect(s.daysToGo(day), 0);
    expect(s.calendarDay(day), 1);
  });

  test('31 Dec is the last day, then the year rolls to a new run', () {
    expect(s.calendarDay(DateTime(2027, 12, 31)), 365);
    expect(s.calendarDay(DateTime(2028, 1, 1)), 1);
    expect(s.isCurrentRun('2027-03-02', DateTime(2027, 12, 31)), isTrue);
    expect(s.isCurrentRun('2027-03-02', DateTime(2028, 1, 1)), isFalse);
    expect(s.isLocked(DateTime(2028, 1, 1)), isFalse);
  });

  test('leap year day 366 clamps to the final day', () {
    expect(s.calendarDay(DateTime(2028, 12, 30)), 365);
    expect(s.calendarDay(DateTime(2028, 12, 31)), 365);
  });

  test('statuses: read is done, unread past is catch-up, then today, ahead',
      () {
    const st = PlanDayStatuses(done: {1, 3}, today: 5);
    expect(st.of(1), DayStatus.done);
    expect(st.of(2), DayStatus.catchUp);
    expect(st.of(5), DayStatus.today);
    expect(st.of(6), DayStatus.ahead);
    // A day read ahead of time is done, not ahead.
    expect(const PlanDayStatuses(done: {9}, today: 5).of(9), DayStatus.done);
    expect(st, const PlanDayStatuses(done: {3, 1}, today: 5));
  });

  test('catch-up count is unread days before today', () {
    expect(s.catchUpCount({}, DateTime(2027, 1, 15)), 14);
    expect(s.catchUpCount({1, 2, 3}, DateTime(2027, 1, 15)), 11);
  });

  test('runFor keys anchored progress per run year', () {
    final a = s.runFor('2027-01-15', DateTime(2027, 6, 1));
    expect(a.anchored, isTrue);
    expect(a.joined, isTrue);
    expect(a.progressId, 'year@2027');
    expect(a.calendarDay, 152);
    final next = s.runFor('2027-01-15', DateTime(2028, 1, 1));
    expect(next.joined, isFalse);
    expect(next.progressId, 'year@2028');
    expect(s.runFor(null, DateTime(2027, 1, 1)).joined, isFalse);
  });

  test('legacy subscribers keep the old progress-driven plan', () {
    expect(s.isLegacy('2026-11-01'), isTrue);
    expect(s.isLegacy('2027-01-01'), isFalse);
    final r = s.runFor('2026-11-01', DateTime(2028, 5, 1));
    expect(r.anchored, isFalse);
    expect(r.joined, isTrue);
    expect(r.progressId, 'year');
  });

  test('a plan with no startsOn is open and not fixed', () {
    final open = PlanSchedule(_plan(startsOn: null, firstRunYear: null));
    expect(open.isFixed, isFalse);
    expect(open.isLocked(DateTime(2020)), isFalse);
    expect(open.startLabel, '');
  });

  test('a bad startsOn is treated as not fixed', () {
    expect(PlanSchedule(_plan(startsOn: '13-40')).isFixed, isFalse);
    expect(PlanSchedule(_plan(startsOn: 'nope')).isFixed, isFalse);
  });

  test('json round trip keeps the fixed start', () {
    final json = _plan().toJson();
    json['days'] = [];
    final back = ReadingPlan.fromJson(json);
    expect(back.startsOn, '01-01');
    expect(back.firstRunYear, 2027);
  });
}
