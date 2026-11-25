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
    expect(s.nextDay({}, '2027-01-01'), 1);
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

  test('late joiner on 15 Jan starts at day 15 with 14 catch-up days', () {
    expect(s.nextDay({}, '2027-01-15'), 15);
    expect(s.nextDay({15}, '2027-01-15'), 16);
    expect(s.catchUpCount({}, DateTime(2027, 1, 15)), 14);
    expect(s.catchUpCount({1, 2, 3}, DateTime(2027, 1, 15)), 11);
  });

  test('catch-up days come back once everything ahead is read', () {
    final done = {for (var i = 15; i <= 365; i++) i};
    expect(s.nextDay(done, '2027-01-15'), 1);
    expect(s.nextDay({for (var i = 1; i <= 365; i++) i}, '2027-01-15'), isNull);
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
