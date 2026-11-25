import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/database_provider.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/core/utils/day_part_provider.dart';
import 'package:openbaptisthymnal/features/daily/domain/plan_schedule.dart';
import 'package:openbaptisthymnal/features/daily/providers/daily_providers.dart';
import 'package:openbaptisthymnal/features/onboarding/providers/onboarding_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/pump_app.dart';

const _year = 'bible-in-a-year';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = testDb();
  });
  tearDown(() => db.close());

  ProviderContainer at(DateTime now) {
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appDatabaseProvider.overrideWithValue(db),
      dayPartClockProvider.overrideWithValue(() => now),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  Future<void> start(ProviderContainer c) async {
    final plan = await c.read(planByIdProvider(_year).future);
    await c.read(startPlanProvider)(plan);
  }

  test('the bundled year plan is fixed to 1 January, first run 2027', () async {
    final plan =
        await at(DateTime(2026, 11, 25)).read(planByIdProvider(_year).future);
    expect(plan.startsOn, '01-01');
    expect(plan.firstRunYear, 2027);
  });

  test('the injected clock drives today', () {
    expect(at(DateTime(2027, 1, 15, 9)).read(todayKeyProvider), '2027-01-15');
  });

  test('before 1 January the year plan cannot be started', () async {
    final c = at(DateTime(2026, 12, 31));
    await start(c);
    expect(await db.readingPlansDao.activePlan(), isNull);
  });

  test('on 1 January it starts at day 1', () async {
    final c = at(DateTime(2027, 1, 1));
    await start(c);
    final r = await c.read(todaysReadingProvider.future);
    expect(r?.day?.dayIndex, 1);
    expect(r?.catchUpDays, 0);
  });

  test('a late joiner on 15 Jan reads today (day 15) with 14 catch-up days',
      () async {
    final c = at(DateTime(2027, 1, 15));
    await start(c);
    final r = await c.read(todaysReadingProvider.future);
    expect(r?.day?.dayIndex, 15);
    expect(r?.catchUpDays, 14);
    expect(r?.progressKey, 'bible-in-a-year@2027');
    expect(r?.statuses?.of(14), DayStatus.catchUp);
    expect(r?.statuses?.of(15), DayStatus.today);
    expect(r?.statuses?.of(16), DayStatus.ahead);
  });

  test('today is the calendar day even for someone who read days 1 to 3',
      () async {
    await start(at(DateTime(2027, 1, 1)));
    for (final d in [1, 2, 3]) {
      await db.readingPlansDao.markPlanDayComplete(
          planId: 'bible-in-a-year@2027',
          dayIndex: d,
          completedAt: DateTime(2027, 1, d));
    }
    final r =
        await at(DateTime(2027, 1, 10)).read(todaysReadingProvider.future);
    expect(r?.day?.dayIndex, 10);
    expect(r?.statuses?.of(2), DayStatus.done);
    expect(r?.statuses?.of(4), DayStatus.catchUp);
    expect(r?.todayRead, isFalse);
  });

  test('reading today shows done and previews tomorrow', () async {
    await start(at(DateTime(2027, 1, 15)));
    await db.readingPlansDao.markPlanDayComplete(
        planId: 'bible-in-a-year@2027',
        dayIndex: 15,
        completedAt: DateTime(2027, 1, 15));
    final r =
        await at(DateTime(2027, 1, 15)).read(todaysReadingProvider.future);
    expect(r?.todayRead, isTrue);
    expect(r?.day?.dayIndex, 16);
  });

  test('finishing the last day shows done, it does not wrap to day 1',
      () async {
    await start(at(DateTime(2027, 1, 20)));
    await db.readingPlansDao.markPlanDayComplete(
        planId: 'bible-in-a-year@2027',
        dayIndex: 365,
        completedAt: DateTime(2027, 12, 31));
    final r =
        await at(DateTime(2027, 12, 31)).read(todaysReadingProvider.future);
    expect(r?.todayRead, isTrue);
    expect(r?.day?.dayIndex, 365);
    expect(r?.isFinished, isFalse);
  });

  test('reading every day finishes the run', () async {
    await start(at(DateTime(2027, 1, 1)));
    for (var d = 1; d <= 365; d++) {
      await db.readingPlansDao.markPlanDayComplete(
          planId: 'bible-in-a-year@2027',
          dayIndex: d,
          completedAt: DateTime(2027, 12, 31));
    }
    final r =
        await at(DateTime(2027, 12, 31)).read(todaysReadingProvider.future);
    expect(r?.isFinished, isTrue);
  });

  test('re-picking later in the run keeps the original join day', () async {
    await start(at(DateTime(2027, 1, 15)));
    await start(at(DateTime(2027, 3, 1)));
    final sub = await db.readingPlansDao.activePlan();
    expect(sub?.startDateKey, '2027-01-15');
  });

  test('legacy subscriber keeps the progress-driven plan, locked or not',
      () async {
    await db.readingPlansDao
        .startPlan(planId: _year, startDateKey: '2026-11-01');
    for (var d = 1; d <= 20; d++) {
      await db.readingPlansDao.markPlanDayComplete(
          planId: _year, dayIndex: d, completedAt: DateTime(2026, 11, 20));
    }
    for (final now in [DateTime(2026, 12, 1), DateTime(2027, 1, 10)]) {
      final r = await at(now).read(todaysReadingProvider.future);
      expect(r?.day?.dayIndex, 21);
      expect(r?.statuses, isNull);
      expect(r?.progressKey, _year);
    }
    // Re-picking while locked resumes rather than being refused.
    final c = at(DateTime(2026, 12, 1));
    await start(c);
    expect((await db.readingPlansDao.activePlan())?.startDateKey, '2026-11-01');
    // And no roll at the next new year.
    final later =
        await at(DateTime(2028, 2, 1)).read(todaysReadingProvider.future);
    expect(later?.day?.dayIndex, 21);
  });

  test('the next year starts clean and never deletes last year', () async {
    await start(at(DateTime(2027, 1, 15)));
    await db.readingPlansDao.markPlanDayComplete(
        planId: 'bible-in-a-year@2027',
        dayIndex: 15,
        completedAt: DateTime(2027, 1, 15));

    final next = at(DateTime(2028, 1, 1));
    expect(await next.read(todaysReadingProvider.future), isNull);
    await start(next);
    final r = await at(DateTime(2028, 1, 1)).read(todaysReadingProvider.future);
    expect(r?.day?.dayIndex, 1);
    expect(r?.completedDays, 0);
    expect(r?.progressKey, 'bible-in-a-year@2028');
    final old = await db.readingPlansDao
        .watchCompletedDayIndexes('bible-in-a-year@2027')
        .first;
    expect(old, {15});
  });

  test('remind me is stored and survives a new container', () {
    final c = at(DateTime(2026, 11, 25));
    c.read(planRemindersProvider.notifier).toggle(_year, true);
    expect(at(DateTime(2026, 11, 25)).read(planRemindersProvider), {_year});
    c.read(planRemindersProvider.notifier).toggle(_year, false);
    expect(at(DateTime(2026, 11, 25)).read(planRemindersProvider), isEmpty);
  });

  test('onboarding never starts the locked plan, even if it was picked',
      () async {
    final c = at(DateTime(2026, 11, 25));
    c.read(onboardingProvider.notifier).setPlan(_year);
    await c.read(onboardingProvider.notifier).complete();
    final active = await db.readingPlansDao.activePlan();
    expect(active?.planId, 'nt-90');
  });
}
