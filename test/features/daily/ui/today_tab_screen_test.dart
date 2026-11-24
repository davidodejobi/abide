import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/theme/app_theme.dart';
import 'package:openbaptisthymnal/features/bible/domain/verse_ref.dart';
import 'package:openbaptisthymnal/features/daily/domain/reading_plan.dart';
import 'package:openbaptisthymnal/features/daily/domain/streak.dart';
import 'package:openbaptisthymnal/features/daily/providers/daily_providers.dart';
import 'package:openbaptisthymnal/features/daily/ui/daily_strings.dart';
import 'package:openbaptisthymnal/features/daily/ui/today_tab_screen.dart';
import 'package:openbaptisthymnal/features/onboarding/providers/onboarding_provider.dart';

ReadingPlan _plan() => ReadingPlan(
      id: 'nt-90',
      title: 'The New Testament in 90 Days',
      description: '',
      days: [
        for (var i = 1; i <= 90; i++)
          PlanDay(dayIndex: i, passages: [VerseRange.tryParse('JHN.15.1-17.26')!]),
      ],
    );

StreakResult _streak({bool today = false}) => StreakResult(
      current: 11,
      completedToday: today,
      graceDaysUsed: 0,
      longest: 23,
      totalDays: 40,
    );

Widget _app(List<Override> overrides, {ThemeData? theme, double scale = 1}) {
  return ProviderScope(
    overrides: [
      userNameProvider.overrideWithValue('Maya'),
      planBookNamesProvider.overrideWith((_) async => {'JHN': 'John'}),
      ...overrides,
    ],
    child: MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: const Scaffold(body: SafeArea(child: TodayTabScreen())),
    ),
  );
}

void main() {


  Future<void> pump(WidgetTester t, Widget w) async {
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(w);
    await t.pump(const Duration(milliseconds: 100));
  }

  testWidgets('Given a plan in progress, Then today shows the day, passage and Start reading',
      (t) async {
    final plan = _plan();
    await pump(
      t,
      _app([
        streakProvider.overrideWithValue(_streak()),
        isTodayCompleteProvider.overrideWithValue(false),
        todaysReadingProvider.overrideWith((_) async =>
            TodaysReading(plan: plan, day: plan.dayAt(41), completedDays: 40)),
      ], scale: 1.3),
    );
    expect(find.text('41'), findsWidgets);
    expect(find.text('John 15–17'), findsOneWidget);
    expect(find.text(DailyStrings.chapters(3)), findsOneWidget);
    expect(find.text(DailyStrings.startReading), findsOneWidget);
    expect(find.text('11'), findsOneWidget); // streak chip
    expect(tester(t), isNull);
  });

  testWidgets('Given today is done, Then it turns to evening and names tomorrow',
      (t) async {
    final plan = _plan();
    await pump(
      t,
      _app([
        streakProvider.overrideWithValue(_streak(today: true)),
        isTodayCompleteProvider.overrideWithValue(true),
        todaysReadingProvider.overrideWith((_) async =>
            TodaysReading(plan: plan, day: plan.dayAt(42), completedDays: 41)),
      ]),
    );
    expect(find.text(DailyStrings.tomorrowDay(42)), findsOneWidget);
    expect(find.text(DailyStrings.dayN(41)), findsOneWidget);
    expect(find.text(DailyStrings.writeNote), findsOneWidget);
    expect(find.text(DailyStrings.startReading), findsNothing);
  });

  testWidgets('Given no plan, Then it offers Choose a plan and no streak chip',
      (t) async {
    await pump(
      t,
      _app([
        streakProvider.overrideWithValue(const StreakResult(
            current: 0, completedToday: false, graceDaysUsed: 0, longest: 0, totalDays: 0)),
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
