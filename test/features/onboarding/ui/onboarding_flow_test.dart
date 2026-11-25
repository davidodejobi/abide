import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/database_provider.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/core/theme/app_theme.dart';
import 'package:openbaptisthymnal/features/bible/domain/verse_ref.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';
import 'package:openbaptisthymnal/features/daily/domain/reading_plan.dart';
import 'package:openbaptisthymnal/features/daily/providers/daily_providers.dart';
import 'package:openbaptisthymnal/features/hymn/providers/hymnal_provider.dart';
import 'package:openbaptisthymnal/features/onboarding/providers/onboarding_provider.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/onboarding_strings.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/screens/bible_screen.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/screens/name_screen.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/screens/plan_screen.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/screens/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/pump_app.dart';

ReadingPlan _plan(String id, String title, int days) => ReadingPlan(
      id: id,
      title: title,
      description: '',
      days: [
        for (var i = 1; i <= days; i++)
          PlanDay(dayIndex: i, passages: [VerseRange.tryParse('JHN.1.1-3.36')!]),
      ],
    );

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = testDb();
  });
  tearDown(() => db.close());

  ProviderContainer container() {
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appDatabaseProvider.overrideWithValue(db),
      availablePlansProvider.overrideWith((_) async => [
            _plan('psalms-30', '30 Days in the Psalms', 30),
            _plan('nt-90', 'The New Testament in 90 Days', 90),
          ]),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  Future<void> pump(WidgetTester t, ProviderContainer c, Widget screen,
      {double scale = 1}) async {
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(body: screen),
      ),
    ));
    await t.pump(const Duration(milliseconds: 200));
    await t.pump(const Duration(milliseconds: 200));
  }

  testWidgets('welcome shows the headline and Begin fires onNext',
      (t) async {
    var next = 0;
    await pump(t, container(), WelcomeScreen(onNext: () => next++));
    expect(find.text(OnboardingStrings.welcomeTitle), findsOneWidget);
    await t.tap(find.text(OnboardingStrings.begin));
    expect(next, 1);
    await t.flushTimers();
  });

  testWidgets('bible step lists the language chips and picks an edition',
      (t) async {
    final c = container();
    await pump(
        t,
        c,
        BibleScreen(step: 1, total: 3, onNext: () {}, onBack: () {}));
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Yorùbá'), findsOneWidget);
    await t.tap(find.text('Berean Standard Bible'));
    await t.pump();
    expect(c.read(onboardingProvider).editionId, 'en-bsb');
    await t.tap(find.text('Yorùbá'));
    await t.pump();
    expect(c.read(onboardingProvider).languageCode, 'yo');
    expect(c.read(onboardingProvider).editionId, 'yo-bmy');
    await t.flushTimers();
  });

  testWidgets('plan step selects a plan and shows the goal card', (t) async {
    final c = container();
    await pump(
        t, c, PlanScreen(step: 2, total: 3, onNext: () {}, onBack: () {}));
    expect(find.text('SELECTED'), findsOneWidget);
    await t.tap(find.text('30 Days in the Psalms'));
    await t.pump();
    expect(c.read(onboardingProvider).planId, 'psalms-30');
    expect(find.text(OnboardingStrings.yourGoalCaps), findsOneWidget);
    await t.flushTimers();
  });

  test('complete saves name, edition, plan and the complete flag', () async {
    final c = container();
    c.read(onboardingProvider.notifier)
      ..setEdition('en-bsb')
      ..setPlan('psalms-30')
      ..setName('  Tolu ');
    await c.read(onboardingProvider.notifier).complete();

    expect(prefs.getBool('onboarding_complete'), isTrue);
    expect(prefs.getString('user_name'), 'Tolu');
    expect(c.read(primaryEditionProvider), 'en-bsb');
    final active = await db.readingPlansDao.watchActivePlan().first;
    expect(active?.planId, 'psalms-30');
  });

  test('complete persists the song language for the next launch', () async {
    final c = container();
    c.read(onboardingProvider.notifier).setLanguage('yo');
    await c.read(onboardingProvider.notifier).complete();
    expect(prefs.getString('song_language'), 'yo');
    final next = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(next.dispose);
    expect(next.read(languageProvider), 'yo');
  });

  testWidgets('name step writes the typed name into the provider',
      (t) async {
    final c = container();
    await pump(
        t,
        c,
        NameScreen(step: 3, total: 3, onDone: () {}, onBack: () {}));
    expect(find.text(OnboardingStrings.nameTitle), findsOneWidget);
    await t.enterText(find.byType(TextField), 'Tolu');
    expect(c.read(onboardingProvider).name, 'Tolu');
    await t.flushTimers();
  });

  testWidgets('scene collapses when the keyboard is up', (t) async {
    final c = container();
    await pump(
        t, c, NameScreen(step: 3, total: 3, onDone: () {}, onBack: () {}));
    final before = t.getTopLeft(find.text(OnboardingStrings.nameTitle)).dy;
    t.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
    addTearDown(t.view.resetViewInsets);
    await t.pump(const Duration(milliseconds: 200));
    final after = t.getTopLeft(find.text(OnboardingStrings.nameTitle)).dy;
    expect(after, lessThan(before - 50));
    expect(t.takeException(), isNull);
    await t.flushTimers();
  });

  for (final (w, h, scale) in [(320.0, 568.0, 2.0), (375.0, 667.0, 3.1)]) {
    testWidgets('no overflow at ${w}x$h @$scale on every step', (t) async {
      final c = container();
      for (final screen in <Widget>[
        BibleScreen(step: 1, total: 3, onNext: () {}, onBack: () {}),
        PlanScreen(step: 2, total: 3, onNext: () {}, onBack: () {}),
        NameScreen(step: 3, total: 3, onDone: () {}, onBack: () {}),
      ]) {
        t.view.physicalSize = Size(w * 3, h * 3);
        t.view.devicePixelRatio = 3;
        addTearDown(t.view.reset);
        await t.pumpWidget(UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(body: screen),
          ),
        ));
        await t.pump(const Duration(milliseconds: 200));
        expect(t.takeException(), isNull);
      }
      await t.flushTimers();
    });
  }

  testWidgets('layout survives large text on every step', (t) async {
    final c = container();
    for (final screen in <Widget>[
      WelcomeScreen(onNext: () {}),
      BibleScreen(step: 1, total: 3, onNext: () {}, onBack: () {}),
      PlanScreen(step: 2, total: 3, onNext: () {}, onBack: () {}),
      NameScreen(step: 3, total: 3, onDone: () {}, onBack: () {}),
    ]) {
      await pump(t, c, screen, scale: 2);
      expect(t.takeException(), isNull);
    }
    await t.flushTimers();
  });
}
