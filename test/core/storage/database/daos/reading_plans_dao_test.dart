import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/reading_plans_dao.dart';

void main() {
  late AppDatabase db;
  late ReadingPlansDao dao;

  // Fixed clock. These rows are compared and counted; a wall-clock timestamp
  // would make the assertions depend on when the suite happened to run.
  final now = DateTime(2026, 1, 15, 9, 30);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = ReadingPlansDao(db);
  });

  tearDown(() => db.close());

  group('Given a fresh database', () {
    group('When the daily tables are queried', () {
      test('Then they exist and are empty', () async {
        // Would throw "no such table" if schemaVersion/createAll had drifted
        // apart from the table registration.
        expect(await dao.completedDayKeys(), isEmpty);
        expect(await dao.activePlan(), isNull);
      });
    });
  });

  group('Given the user marks a day complete', () {
    group('When they mark the same day twice', () {
      test('Then it stays one row -- the date key makes it idempotent',
          () async {
        // This is the check deliberately NOT written against computeStreak: at
        // that layer the input is a Set, so a duplicate cannot exist. Here it
        // can, and the primary key is what stops it. Double-tapping "Mark as
        // read" must not be able to corrupt the streak.
        await dao.markDayComplete(
          dateKey: '2026-01-15',
          source: 'plan',
          completedAt: now,
        );
        await dao.markDayComplete(
          dateKey: '2026-01-15',
          source: 'chapter',
          completedAt: now,
        );

        expect(await dao.completedDayKeys(), {'2026-01-15'});

        final rows = await db.select(db.readingDays).get();
        expect(rows, hasLength(1), reason: 'one row per calendar day');
        expect(
          rows.single.source,
          'chapter',
          reason: 'insertOnConflictUpdate overwrites rather than throwing',
        );
      });
    });

    group('When they unmark it', () {
      test('Then the day is gone, so a mis-tap is recoverable', () async {
        // A streak the user cannot correct is a streak they stop trusting.
        await dao.markDayComplete(
          dateKey: '2026-01-15',
          source: 'plan',
          completedAt: now,
        );

        await dao.unmarkDay('2026-01-15');

        expect(await dao.completedDayKeys(), isEmpty);
      });
    });

    group('When several days are marked', () {
      test('Then the watcher emits the whole set, ready for computeStreak',
          () async {
        await dao.markDayComplete(
          dateKey: '2026-01-14',
          source: 'plan',
          completedAt: now,
        );
        await dao.markDayComplete(
          dateKey: '2026-01-15',
          source: 'altar',
          completedAt: now,
        );

        expect(
          await dao.watchCompletedDayKeys().first,
          {'2026-01-14', '2026-01-15'},
        );
      });
    });
  });

  group('Given a plan is started', () {
    group('When no plan was active before', () {
      test('Then it becomes the active plan', () async {
        await dao.startPlan(
          planId: 'bible-in-a-year',
          startDateKey: '2026-01-15',
        );

        final active = await dao.activePlan();
        expect(active!.planId, 'bible-in-a-year');
        expect(active.startDateKey, '2026-01-15');
        expect(active.isActive, isTrue);
      });
    });

    group('When another plan was already active', () {
      test('Then exactly one plan is active, and it is the new one', () async {
        // watchActivePlan uses watchSingleOrNull, which THROWS on two rows
        // rather than picking one. So "deactivate the old before inserting the
        // new" is a correctness requirement, not tidiness.
        await dao.startPlan(planId: 'nt-90', startDateKey: '2026-01-01');

        await dao.startPlan(
          planId: 'psalms-30',
          startDateKey: '2026-01-15',
        );

        final active = await dao.activePlan();
        expect(active!.planId, 'psalms-30');

        // The stream would throw here if two rows were left active.
        expect((await dao.watchActivePlan().first)!.planId, 'psalms-30');
      });
    });

    group('When a previously abandoned plan is restarted', () {
      test('Then its old progress is still there, so it resumes', () async {
        await dao.startPlan(planId: 'nt-90', startDateKey: '2026-01-01');
        await dao.markPlanDayComplete(
          planId: 'nt-90',
          dayIndex: 1,
          completedAt: now,
        );

        await dao.startPlan(planId: 'psalms-30', startDateKey: '2026-01-15');
        await dao.startPlan(planId: 'nt-90', startDateKey: '2026-01-01');

        expect(
          await dao.watchCompletedDayIndexes('nt-90').first,
          {1},
          reason: 'switching away and back must not wipe progress',
        );
      });
    });
  });

  group('Given plan progress', () {
    group('When the same plan day is marked twice', () {
      test('Then the deterministic id keeps it to one row', () async {
        await dao.markPlanDayComplete(
          planId: 'nt-90',
          dayIndex: 3,
          completedAt: now,
        );
        await dao.markPlanDayComplete(
          planId: 'nt-90',
          dayIndex: 3,
          completedAt: now.add(const Duration(hours: 2)),
        );

        expect(await dao.watchCompletedDayIndexes('nt-90').first, {3});
      });
    });

    group('When two plans have progress', () {
      test('Then each plan sees only its own days', () async {
        await dao.markPlanDayComplete(
          planId: 'nt-90',
          dayIndex: 1,
          completedAt: now,
        );
        await dao.markPlanDayComplete(
          planId: 'psalms-30',
          dayIndex: 7,
          completedAt: now,
        );

        expect(await dao.watchCompletedDayIndexes('nt-90').first, {1});
        expect(await dao.watchCompletedDayIndexes('psalms-30').first, {7});
      });
    });

    group('When a plan day is unmarked', () {
      test('Then only that day goes', () async {
        await dao.markPlanDayComplete(
          planId: 'nt-90',
          dayIndex: 1,
          completedAt: now,
        );
        await dao.markPlanDayComplete(
          planId: 'nt-90',
          dayIndex: 2,
          completedAt: now,
        );

        await dao.unmarkPlanDay(planId: 'nt-90', dayIndex: 1);

        expect(await dao.watchCompletedDayIndexes('nt-90').first, {2});
      });
    });

    group('When the user restarts a plan from the beginning', () {
      test('Then that plan clears, and other plans are untouched', () async {
        await dao.markPlanDayComplete(
          planId: 'nt-90',
          dayIndex: 1,
          completedAt: now,
        );
        await dao.markPlanDayComplete(
          planId: 'psalms-30',
          dayIndex: 4,
          completedAt: now,
        );

        await dao.clearPlanProgress('nt-90');

        expect(await dao.watchCompletedDayIndexes('nt-90').first, isEmpty);
        expect(
          await dao.watchCompletedDayIndexes('psalms-30').first,
          {4},
          reason: 'restarting one plan must not touch another',
        );
      });
    });
  });

  group('Given "Mark read" is tapped', () {
    group('When the reading is recorded', () {
      test('Then the streak day and the plan day land together', () async {
        // One transaction, not two writes. Recorded separately, a failure
        // between them credits a streak day for a plan day that never advanced,
        // and the card goes on offering the passage it just said you had read.
        await dao.markReadingComplete(
          dateKey: '2026-01-15',
          source: 'plan',
          planId: 'nt-90',
          dayIndex: 1,
          completedAt: now,
        );

        expect(await dao.completedDayKeys(), {'2026-01-15'});
        expect(await dao.watchCompletedDayIndexes('nt-90').first, {1});
      });

      test('Then a repeat tap on the same day changes nothing', () async {
        // Both keys are deterministic, so the double-tap is a no-op twice over.
        for (var i = 0; i < 3; i++) {
          await dao.markReadingComplete(
            dateKey: '2026-01-15',
            source: 'plan',
            planId: 'nt-90',
            dayIndex: 1,
            completedAt: now,
          );
        }

        expect(await db.select(db.readingDays).get(), hasLength(1));
        expect(await db.select(db.planDayProgress).get(), hasLength(1));
      });
    });
  });

  group('Given a reader three days behind catches up in one sitting', () {
    group('When they mark three plan days on the same calendar day', () {
      test('Then the plan advances three days and the streak advances one',
          () async {
        // What "Mark read" does, three times over, in one evening. Both halves
        // matter and they pull in opposite directions:
        //
        //   - the plan MUST advance three days, or catching up is impossible and
        //     someone who fell behind can never get back on schedule.
        //   - the streak MUST advance one, because you cannot catch up on
        //     turning up. Three days of reading in one night is one day of
        //     showing up, and pretending otherwise makes the streak a lie.
        //
        // The date primary key on reading_days is what enforces the second half:
        // marks two and three are no-ops.
        // Exactly what tapping "Mark read" three times does.
        for (final planDay in [1, 2, 3]) {
          await dao.markReadingComplete(
            dateKey: '2026-01-15',
            source: 'plan',
            planId: 'nt-90',
            dayIndex: planDay,
            completedAt: now,
          );
        }

        expect(await dao.watchCompletedDayIndexes('nt-90').first, {1, 2, 3});
        expect(
          await dao.completedDayKeys(),
          {'2026-01-15'},
          reason: 'one evening of reading is one day of streak, not three',
        );
      });
    });
  });

  group('Given someone ticks off plan days they never read', () {
    group('When the streak is looked at', () {
      test('Then it is untouched -- plan progress cannot manufacture a streak',
          () async {
        // The anti-gaming invariant, stated where it can be broken. Plan
        // progress and reading days are separate tables written by separate
        // calls, so marking 90 plan days produces exactly zero streak days.
        // If someone ever "tidies" markPlanDayComplete into also writing a
        // reading day, the streak becomes a thing you can fake in an afternoon
        // and this test is what stops them.
        for (var day = 1; day <= 90; day++) {
          await dao.markPlanDayComplete(
            planId: 'nt-90',
            dayIndex: day,
            completedAt: now,
          );
        }

        expect(await dao.watchCompletedDayIndexes('nt-90').first, hasLength(90));
        expect(
          await dao.completedDayKeys(),
          isEmpty,
          reason: 'not one day of streak was earned by ticking boxes',
        );
      });
    });
  });

  group('Given a completed calendar day and a completed plan day', () {
    group('When they are recorded', () {
      test('Then they are independent -- catching up is not a longer streak',
          () async {
        // Someone catching up reads three plan days in one sitting. That is one
        // calendar day for the streak and three days of plan progress, and
        // conflating the two would let a person binge their way to a 30-day
        // streak in an afternoon.
        await dao.markDayComplete(
          dateKey: '2026-01-15',
          source: 'plan',
          completedAt: now,
        );
        for (final day in [1, 2, 3]) {
          await dao.markPlanDayComplete(
            planId: 'nt-90',
            dayIndex: day,
            completedAt: now,
          );
        }

        expect(await dao.completedDayKeys(), hasLength(1));
        expect(await dao.watchCompletedDayIndexes('nt-90').first, {1, 2, 3});
      });
    });
  });
}
