import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/database_provider.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/core/utils/day_part_provider.dart';
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

  test('a late joiner on 15 Jan reads day 15 with 14 catch-up days', () async {
    final c = at(DateTime(2027, 1, 15));
    await start(c);
    final r = await c.read(todaysReadingProvider.future);
    expect(r?.day?.dayIndex, 15);
    expect(r?.catchUpDays, 14);
  });

  test('re-picking later in the run keeps the original join day', () async {
    await start(at(DateTime(2027, 1, 15)));
    final later = at(DateTime(2027, 3, 1));
    await start(later);
    final r = await later.read(todaysReadingProvider.future);
    expect(r?.day?.dayIndex, 15);
  });

  test('next 1 Jan: last year is a finished run and a new one starts clean',
      () async {
    await start(at(DateTime(2027, 1, 15)));
    await db.readingPlansDao.markPlanDayComplete(
        planId: _year, dayIndex: 15, completedAt: DateTime(2027, 1, 15));

    final next = at(DateTime(2028, 1, 1));
    expect(await next.read(todaysReadingProvider.future), isNull);
    await start(next);
    final r = await at(DateTime(2028, 1, 1)).read(todaysReadingProvider.future);
    expect(r?.day?.dayIndex, 1);
    expect(r?.completedDays, 0);
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
