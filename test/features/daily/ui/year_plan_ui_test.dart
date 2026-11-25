import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/core/theme/app_theme.dart';
import 'package:openbaptisthymnal/core/utils/day_part_provider.dart';
import 'package:openbaptisthymnal/features/daily/domain/reading_plan.dart';
import 'package:openbaptisthymnal/features/daily/providers/daily_providers.dart';
import 'package:openbaptisthymnal/features/daily/ui/daily_strings.dart';
import 'package:openbaptisthymnal/features/daily/ui/widgets/plan_option_tile.dart';
import 'package:openbaptisthymnal/features/onboarding/providers/onboarding_provider.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/screens/plan_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

ReadingPlan _plan(String id, int days, {bool fixed = false}) => ReadingPlan(
      id: id,
      title: id == 'bible-in-a-year' ? 'The Bible in a Year' : id,
      description: '',
      days: [
        for (var i = 1; i <= days; i++) PlanDay(dayIndex: i, passages: const [])
      ],
      startsOn: fixed ? '01-01' : null,
      firstRunYear: fixed ? 2027 : null,
    );

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer container(DateTime now) {
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      dayPartClockProvider.overrideWithValue(() => now),
      availablePlansProvider.overrideWith((_) async => [
            _plan('psalms-30', 30),
            _plan('nt-90', 90),
            _plan('bible-in-a-year', 365, fixed: true),
          ]),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  Future<void> pump(WidgetTester t, ProviderContainer c, Widget child) async {
    t.view.physicalSize = const Size(390 * 3, 1400 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: child),
      ),
    ));
    await t.pump(const Duration(milliseconds: 200));
    await t.pump(const Duration(milliseconds: 200));
  }

  testWidgets('locked year plan shows the countdown, remind toggle and warm-up',
      (t) async {
    final c = container(DateTime(2026, 11, 25));
    var taps = 0;
    await pump(
        t,
        c,
        SingleChildScrollView(
            child: PlanTile(
                plan: _plan('bible-in-a-year', 365, fixed: true),
                selected: false,
                onTap: () => taps++)));
    expect(find.text(DailyStrings.startsOnLocked('1 January', 37)),
        findsOneWidget);
    expect(find.text(DailyStrings.warmUp), findsOneWidget);

    await t.tap(find.text('The Bible in a Year'));
    expect(taps, 0);

    await t.tap(find.byType(Switch));
    await t.pump();
    expect(c.read(planRemindersProvider), {'bible-in-a-year'});
  });

  testWidgets('once open the tile is a normal, tappable plan', (t) async {
    final c = container(DateTime(2027, 1, 1));
    var taps = 0;
    await pump(
        t,
        c,
        SingleChildScrollView(
            child: PlanTile(
                plan: _plan('bible-in-a-year', 365, fixed: true),
                selected: false,
                onTap: () => taps++)));
    expect(find.byType(Switch), findsNothing);
    await t.tap(find.text('The Bible in a Year'));
    expect(taps, 1);
  });

  testWidgets(
      'onboarding defaults to NT in 90 days and ignores the locked plan',
      (t) async {
    final c = container(DateTime(2026, 11, 25));
    await pump(
        t, c, PlanScreen(step: 2, total: 3, onNext: () {}, onBack: () {}));
    expect(c.read(onboardingProvider).planId, 'nt-90');
    await t.tap(find.text('The Bible in a Year'));
    await t.pump();
    expect(c.read(onboardingProvider).planId, 'nt-90');
    expect(find.text('SELECTED'), findsOneWidget);
  });

  testWidgets('line singular for one day to go', (t) async {
    expect(DailyStrings.startsOnLocked('1 January', 1),
        'Starts 1 January · 1 day to go');
    expect(DailyStrings.yearStartsIn('The Bible in a Year', 1),
        'The Bible in a Year starts tomorrow');
    expect(DailyStrings.catchUp(1), contains('1 earlier day'));
  });
}
