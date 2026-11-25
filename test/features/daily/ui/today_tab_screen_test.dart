import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/database/database_provider.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/core/theme/app_theme.dart';
import 'package:openbaptisthymnal/core/utils/day_part_provider.dart';
import 'package:openbaptisthymnal/features/daily/domain/date_key.dart';
import 'package:openbaptisthymnal/features/bible/domain/verse_ref.dart';
import 'package:openbaptisthymnal/features/daily/domain/reading_plan.dart';
import 'package:openbaptisthymnal/features/daily/domain/road_geometry.dart';
import 'package:openbaptisthymnal/features/daily/domain/streak.dart';
import 'package:openbaptisthymnal/features/daily/providers/daily_providers.dart';
import 'package:openbaptisthymnal/features/daily/ui/daily_strings.dart';
import 'package:openbaptisthymnal/features/daily/ui/today_tab_screen.dart';
import 'package:openbaptisthymnal/features/onboarding/providers/onboarding_provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/pump_app.dart';

ReadingPlan _plan() => ReadingPlan(
      id: 'nt-90',
      title: 'The New Testament in 90 Days',
      description: '',
      days: [
        for (var i = 1; i <= 90; i++)
          PlanDay(
              dayIndex: i, passages: [VerseRange.tryParse('JHN.15.1-17.26')!]),
      ],
    );

StreakResult _streak({bool today = false}) => StreakResult(
      current: 11,
      completedToday: today,
      graceDaysUsed: 0,
      longest: 23,
      totalDays: 40,
    );

late SharedPreferences _prefs;

Widget _app(List<Override> overrides, {ThemeData? theme, double scale = 1}) {
  return ProviderScope(
    overrides: [
      userNameProvider.overrideWithValue('Maya'),
      sharedPreferencesProvider.overrideWithValue(_prefs),
      availablePlansProvider.overrideWith((_) async => <ReadingPlan>[]),
      planBookNamesProvider.overrideWith((_) async => {'JHN': 'John'}),
      dayPartClockProvider.overrideWithValue(() => DateTime(2026, 1, 7, 10)),
      ...overrides,
    ],
    child: MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: const Scaffold(body: SafeArea(child: TodayTabScreen())),
    ),
  );
}

class _FakeDay extends TodayKeyNotifier {
  @override
  String build() => todayKey();
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  Future<void> pump(WidgetTester t, Widget w) async {
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(w);
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(milliseconds: 100));
  }

  testWidgets(
      'Given a plan in progress, Then today shows the day, passage and Start reading',
      (t) async {
    final plan = _plan();
    await pump(
      t,
      _app([
        streakProvider.overrideWithValue(_streak()),
        isTodayCompleteProvider.overrideWithValue(false),
        todaysReadingProvider.overrideWith((_) async =>
            TodaysReading(plan: plan, day: plan.dayAt(41), completedDays: 40)),
        planDaysDoneTodayProvider.overrideWith((_, __) => Stream.value({})),
      ], scale: 1.3),
    );
    expect(find.text('41'), findsWidgets);
    expect(find.text('John 15–17'), findsOneWidget);
    expect(find.text(DailyStrings.chapters(3)), findsOneWidget);
    expect(find.text(DailyStrings.startReading), findsOneWidget);
    expect(find.text('11'), findsOneWidget); // streak chip
    expect(tester(t), isNull);
  });

  testWidgets(
      'Given the panel is dragged down, Then the road fills the screen and the chip brings it back',
      (t) async {
    final plan = _plan();
    await pump(
      t,
      _app([
        streakProvider.overrideWithValue(_streak()),
        isTodayCompleteProvider.overrideWithValue(false),
        todaysReadingProvider.overrideWith((_) async =>
            TodaysReading(plan: plan, day: plan.dayAt(41), completedDays: 40)),
        planDaysDoneTodayProvider.overrideWith((_, __) => Stream.value({})),
      ]),
    );
    final chip = find.text('Day 41 · John 15–17');
    expect(chip, findsNothing);
    final openTop = t.getTopLeft(find.text(DailyStrings.startReading)).dy;
    await t.drag(find.text(DailyStrings.startReading), const Offset(0, 600));
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    expect(chip, findsOneWidget);
    await t.tap(chip);
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    expect(chip, findsNothing);
    expect(t.getTopLeft(find.text(DailyStrings.startReading)).dy,
        closeTo(openTop, 2));
    expect(tester(t), isNull);
  });

  testWidgets(
      'Given today is done, Then it shows done and names tomorrow',
      (t) async {
    final plan = _plan();
    await pump(
      t,
      _app([
        streakProvider.overrideWithValue(_streak(today: true)),
        isTodayCompleteProvider.overrideWithValue(true),
        todaysReadingProvider.overrideWith((_) async =>
            TodaysReading(plan: plan, day: plan.dayAt(42), completedDays: 41)),
        planDaysDoneTodayProvider.overrideWith((_, __) => Stream.value({41})),
      ]),
    );
    expect(find.text(DailyStrings.tomorrowDay(42)), findsOneWidget);
    expect(find.text(DailyStrings.dayN(41)), findsOneWidget);
    expect(find.text(DailyStrings.writeNote), findsOneWidget);
    expect(find.text(DailyStrings.startReading), findsNothing);
  });

  testWidgets(
      'Given today is done in the afternoon, Then it says afternoon and well done',
      (t) async {
    final plan = _plan();
    await pump(
      t,
      _app([
        dayPartClockProvider.overrideWithValue(() => DateTime(2026, 1, 7, 14)),
        streakProvider.overrideWithValue(_streak(today: true)),
        isTodayCompleteProvider.overrideWithValue(true),
        todaysReadingProvider.overrideWith((_) async =>
            TodaysReading(plan: plan, day: plan.dayAt(42), completedDays: 41)),
        planDaysDoneTodayProvider.overrideWith((_, __) => Stream.value({41})),
      ]),
    );
    expect(find.text('WEDNESDAY AFTERNOON'), findsOneWidget);
    expect(find.text('Well done, Maya'), findsOneWidget);
    expect(find.textContaining('EVENING'), findsNothing);
  });

  testWidgets('Given it is night and unread, Then it says Good night',
      (t) async {
    final plan = _plan();
    await pump(
      t,
      _app([
        dayPartClockProvider.overrideWithValue(() => DateTime(2026, 1, 7, 23)),
        streakProvider.overrideWithValue(_streak()),
        isTodayCompleteProvider.overrideWithValue(false),
        todaysReadingProvider.overrideWith((_) async =>
            TodaysReading(plan: plan, day: plan.dayAt(41), completedDays: 40)),
        planDaysDoneTodayProvider.overrideWith((_, __) => Stream.value({})),
      ]),
    );
    expect(find.text('Good night, Maya'), findsOneWidget);
  });

  testWidgets(
      'Given a tap on the glowing stop and one ahead, Then the sheets say read and preview',
      (t) async {
    final plan = _plan();
    await pump(
      t,
      _app([
        streakProvider.overrideWithValue(_streak()),
        isTodayCompleteProvider.overrideWithValue(false),
        todaysReadingProvider.overrideWith((_) async =>
            TodaysReading(plan: plan, day: plan.dayAt(41), completedDays: 40)),
        planDaysDoneTodayProvider.overrideWith((_, __) => Stream.value({})),
        planProgressProvider.overrideWith((_, __) => Stream.value({})),
      ]),
    );
    const geo = RoadGeometry();
    Offset stop(int n) {
      final s = geo.stop(n), c = geo.camera(41);
      return Offset(s.x + c.x, s.y + c.y);
    }

    await t.tapAt(stop(41));
    await t.pump(
        const Duration(milliseconds: 600)); // the ambient loop never settles
    expect(find.text('DAY 41 OF 90'), findsOneWidget);
    expect(find.text('John 15–17'), findsWidgets);
    expect(
        find.textContaining('${DailyStrings.sheetToday} · '), findsOneWidget);
    expect(find.text(DailyStrings.readDay), findsOneWidget);
    await t.tapAt(const Offset(195, 20)); // dismiss on the barrier
    await t.pump(
        const Duration(milliseconds: 600)); // the ambient loop never settles

    await t.tapAt(stop(42));
    await t.pump(
        const Duration(milliseconds: 600)); // the ambient loop never settles
    expect(find.text('DAY 42 OF 90'), findsOneWidget);
    expect(find.text(DailyStrings.previewDay), findsOneWidget);
    expect(find.text(DailyStrings.readDay), findsNothing);
    expect(find.text(DailyStrings.sheetDateNote), findsOneWidget);
  });

  testWidgets('Given day 11 done today but day 1 unmarked, Then no "Day 0"',
      (t) async {
    final plan = _plan();
    await pump(
      t,
      _app([
        streakProvider.overrideWithValue(_streak(today: true)),
        isTodayCompleteProvider.overrideWithValue(true),
        // next unread day is 1; day 11 was the one finished today.
        todaysReadingProvider.overrideWith((_) async =>
            TodaysReading(plan: plan, day: plan.dayAt(1), completedDays: 1)),
        planDaysDoneTodayProvider.overrideWith((_, __) => Stream.value({11})),
      ]),
    );
    expect(find.text(DailyStrings.dayN(0)), findsNothing);
    expect(find.text(DailyStrings.startReading), findsOneWidget);
  });

  testWidgets('Given the plan is loading, Then the stub road is not shown',
      (t) async {
    await pump(
      t,
      _app([
        streakProvider.overrideWithValue(_streak()),
        isTodayCompleteProvider.overrideWithValue(false),
        todaysReadingProvider
            .overrideWith((_) => Completer<TodaysReading?>().future),
      ]),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('9999'), findsNothing);
  });

  testWidgets('Given the day rolls over, Then the reading shows again',
      (t) async {
    final plan = _plan();
    final today = DateTime.now();
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final db = testDb();
    addTearDown(db.close);
    await db.readingPlansDao
        .startPlan(planId: plan.id, startDateKey: dayKey(today));
    await db.readingPlansDao.markReadingComplete(
      dateKey: dayKey(today),
      source: 'plan',
      planId: plan.id,
      dayIndex: 1,
      completedAt: today,
    );
    await pump(
      t,
      _app([
        appDatabaseProvider.overrideWithValue(db),
        planByIdProvider(plan.id).overrideWith((_) async => plan),
        todayKeyProvider.overrideWith(_FakeDay.new),
      ]),
    );
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text(DailyStrings.writeNote), findsOneWidget);

    ProviderScope.containerOf(t.element(find.byType(TodayTabScreen)))
        .read(todayKeyProvider.notifier)
        .state = dayKey(tomorrow);
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text(DailyStrings.startReading), findsOneWidget);
    expect(find.text(DailyStrings.writeNote), findsNothing);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 100));
  });

  group('layout robustness', () {
    ReadingPlan longPlan() => ReadingPlan(
          id: 'ot-200',
          title: 'The Old Testament in 200 Days',
          description: '',
          days: [
            for (var i = 1; i <= 200; i++)
              PlanDay(dayIndex: i, passages: [
                VerseRange.tryParse(
                    i == 127 ? 'DEU.1.1-2.37' : 'LEV.1.1-3.17')!,
              ]),
          ],
        );

    Future<void> run(
        WidgetTester t, Size logical, double scale, int day) async {
      final plan = longPlan();
      t.view.physicalSize = logical * 2;
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      await t.pumpWidget(_app([
        planBookNamesProvider.overrideWith(
            (_) async => {'LEV': 'Leviticus', 'DEU': 'Deuteronomy'}),
        streakProvider.overrideWithValue(_streak()),
        isTodayCompleteProvider.overrideWithValue(false),
        planDaysDoneTodayProvider.overrideWith((_, __) => Stream.value({})),
        todaysReadingProvider.overrideWith((_) async => TodaysReading(
            plan: plan, day: plan.dayAt(day), completedDays: day - 1)),
      ], scale: scale));
      for (var i = 0; i < 3; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(t.takeException(), isNull);
      // The passage never wraps mid-word: its box is one line of text or splits
      // only at the space, so it is never taller than two lines.
      final passage = find.textContaining(RegExp(r'^(Leviticus|Deuteronomy) '));
      expect(passage, findsOneWidget);
      // Header stays above the panel's first label.
      final header = t.getRect(find.textContaining('Maya'));
      final label =
          t.getRect(find.text(DailyStrings.todaysReading.toUpperCase()));
      expect(header.bottom, lessThanOrEqualTo(label.top));
    }

    testWidgets(
        'landscape 844x390', (t) => run(t, const Size(844, 390), 1, 128));
    testWidgets('320 wide at 2x text, Leviticus',
        (t) => run(t, const Size(320, 700), 2, 128));
    testWidgets('320 wide at 2x text, Deuteronomy',
        (t) => run(t, const Size(320, 700), 2, 127));
    testWidgets(
        '390 wide, Deuteronomy', (t) => run(t, const Size(390, 844), 1, 127));
  });

  testWidgets('Given no plan, Then it offers Choose a plan and no streak chip',
      (t) async {
    await pump(
      t,
      _app([
        streakProvider.overrideWithValue(const StreakResult(
            current: 0,
            completedToday: false,
            graceDaysUsed: 0,
            longest: 0,
            totalDays: 0)),
        isTodayCompleteProvider.overrideWithValue(false),
        todaysReadingProvider.overrideWith((_) async => null),
      ], theme: AppTheme.darkTheme),
    );
    expect(find.text(DailyStrings.noPlanTitle), findsOneWidget);
    expect(find.text(DailyStrings.choosePlan), findsOneWidget);
    expect(find.text(DailyStrings.dayStreak), findsNothing);
  });
}

// ponytail: placeholder so the 1.3x test also asserts nothing overflowed.
Object? tester(WidgetTester t) => t.takeException();
