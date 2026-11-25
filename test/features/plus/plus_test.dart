import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/core/theme/app_theme.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/screens/plus_offer_screen.dart';
import 'package:openbaptisthymnal/features/plus/data/purchase_service.dart';
import 'package:openbaptisthymnal/features/plus/domain/plus_rules.dart';
import 'package:openbaptisthymnal/features/plus/plus_config.dart';
import 'package:openbaptisthymnal/features/plus/providers/plus_providers.dart';
import 'package:openbaptisthymnal/features/plus/ui/plus_gate.dart';
import 'package:openbaptisthymnal/features/plus/ui/trial_reminder_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/pump_app.dart';

void main() {
  late SharedPreferences prefs;
  final start = DateTime(2026, 12, 1);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('rules', () {
    test('free by default, offer shown, features gated', () {
      const e = Entitlement();
      expect(showOnboardingOffer(e, enabled: true), isTrue);
      for (final f in PlusFeature.values) {
        expect(isGated(e, f, enabled: true), isTrue);
      }
    });

    test('Plus readers are not offered or gated', () {
      const e = Entitlement(isPlus: true);
      expect(showOnboardingOffer(e, enabled: true), isFalse);
      expect(isGated(e, PlusFeature.sync, enabled: true), isFalse);
    });

    test('release gate: off means no offer and nothing gated', () {
      const e = Entitlement();
      expect(showOnboardingOffer(e, enabled: false), isFalse);
      for (final f in PlusFeature.values) {
        expect(isGated(e, f, enabled: false), isFalse);
      }
    });

    test('release gate selector: debug or the flag turns Plus on', () {
      expect(plusFeaturesEnabled(debug: false, flag: false), isFalse);
      expect(plusFeaturesEnabled(debug: true, flag: false), isTrue);
      expect(plusFeaturesEnabled(debug: false, flag: true), isTrue);
    });

    test('day-5 reminder window', () {
      final e = Entitlement(isPlus: true, trialStartedAt: start);
      expect(trialReminderDue(e, start.add(const Duration(days: 3))), isFalse);
      expect(trialReminderDue(e, start.add(const Duration(days: 4))), isTrue);
      expect(trialReminderDue(e, start.add(const Duration(days: 6))), isTrue);
      expect(trialReminderDue(e, start.add(const Duration(days: 7))), isFalse);
      expect(
          trialReminderDue(e.copyWith(reminderDismissed: true),
              start.add(const Duration(days: 4))),
          isFalse);
      expect(trialReminderDue(const Entitlement(isPlus: true), start), isFalse);
    });

    test('reading code never touches the Plus gate', () {
      // Bible reading, hymns and the year plan (daily) must never ask for Plus.
      for (final dir in ['lib/features/bible', 'lib/features/hymn', 'lib/features/daily']) {
        for (final f in Directory(dir).listSync(recursive: true)) {
          if (f is! File || !f.path.endsWith('.dart')) continue;
          final src = f.readAsStringSync();
          expect(src.contains('requirePlus'), isFalse, reason: f.path);
          expect(src.contains('features/plus/'), isFalse, reason: f.path);
        }
      }
    });
  });

  group('release gate in the providers', () {
    ProviderContainer container({required bool enabled}) {
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        plusEnabledProvider.overrideWithValue(enabled),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    test('off: purchases fail and Plus is never granted', () async {
      await prefs.setBool('plus_active', true); // even a stale stored grant
      final c = container(enabled: false);
      expect(c.read(plusProvider).isPlus, isFalse);
      final r = await c.read(plusProvider.notifier).startTrial(PlusPlan.annual);
      expect(r, PurchaseOutcome.failed);
      await c.read(plusProvider.notifier).debugSet(true);
      expect(c.read(plusProvider).isPlus, isFalse);
      expect(await c.read(plusProvider.notifier).restore(),
          PurchaseOutcome.failed);
    });

    test('on: a trial grants Plus and remembers the plan', () async {
      final c = container(enabled: true);
      c.read(purchaseServiceProvider); // fake
      final r = await c.read(plusProvider.notifier).startTrial(PlusPlan.monthly);
      expect(r, PurchaseOutcome.success);
      expect(c.read(plusProvider).isPlus, isTrue);
      expect(c.read(plusProvider).plan, PlusPlan.monthly);
      expect(c.read(entitlementRepositoryProvider).read().plan,
          PlusPlan.monthly);
    }, timeout: const Timeout(Duration(seconds: 10)));
  });

  ProviderScope scope(Widget child, {bool enabled = true}) =>
      ProviderScope(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        plusEnabledProvider.overrideWithValue(enabled),
      ], child: child);

  Widget gateButton(void Function(bool) onResult, {void Function()? plans}) =>
      Consumer(
        builder: (context, ref, _) => TextButton(
          onPressed: () async => onResult(await requirePlus(
              context, ref, PlusFeature.sync,
              openPlans: plans)),
          child: const Text('open'),
        ),
      );

  // The sheet route lives above the Scaffold, so the scope must sit above
  // MaterialApp, as in the real app.
  Future<void> pumpGate(WidgetTester t, void Function(bool) onResult,
      {bool enabled = true, void Function()? plans}) async {
    await t.pumpWidget(scope(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(body: gateButton(onResult, plans: plans)),
      ),
      enabled: enabled,
    ));
    await t.pump();
  }

  Future<void> open(WidgetTester t) async {
    await t.tap(find.text('open'));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
  }

  testWidgets('gate sheet opens for free readers, Not now closes it',
      (t) async {
    bool? result;
    await pumpGate(t, (r) => result = r);
    await open(t);
    expect(find.text(PlusFeature.sync.title), findsOneWidget);
    await t.tap(find.text(PlusStrings.notNow));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(find.text(PlusStrings.notNow), findsNothing);
    expect(result, isFalse);
  });

  testWidgets('See Plus plans opens the Plus screen', (t) async {
    var opened = 0;
    await pumpGate(t, (_) {}, plans: () => opened++);
    await open(t);
    await t.tap(find.text(PlusStrings.seePlans));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(opened, 1);
  });

  testWidgets('gate lets Plus readers through without a sheet', (t) async {
    await prefs.setBool('plus_active', true);
    bool? result;
    await pumpGate(t, (r) => result = r);
    await open(t);
    expect(find.text(PlusStrings.notNow), findsNothing);
    expect(result, isTrue);
  });

  testWidgets('gate is a no-op when Plus is switched off', (t) async {
    bool? result;
    await pumpGate(t, (r) => result = r, enabled: false);
    await open(t);
    expect(find.text(PlusStrings.notNow), findsNothing);
    expect(result, isTrue);
  });

  testWidgets('onboarding offer: Continue free skips, See plans opens plans',
      (t) async {
    var done = 0, plans = 0;
    await t.pumpApp(scope(PlusOfferScreen(
        onDone: () => done++, onSeePlans: () => plans++)));
    await t.tap(find.text(PlusStrings.continueFree));
    await t.pump();
    await t.tap(find.text(PlusStrings.seePlans));
    await t.pump();
    expect(done, 1);
    expect(plans, 1);
    final c = ProviderScope.containerOf(t.element(find.byType(PlusOfferScreen)));
    expect(c.read(plusProvider).isPlus, isFalse);
  });

  testWidgets('reminder: day 5 only, long date, the chosen plan price',
      (t) async {
    await prefs.setBool('plus_active', true);
    await prefs.setString('plus_plan', 'monthly');
    await prefs.setInt('plus_trial_start', start.millisecondsSinceEpoch);
    await t.pumpApp(
        scope(TrialReminderCard(now: start.add(const Duration(days: 2)))));
    expect(find.text(PlusStrings.manage), findsNothing);
    await t.pumpApp(
        scope(TrialReminderCard(now: start.add(const Duration(days: 4)))));
    expect(find.text(PlusStrings.manage), findsOneWidget);
    expect(find.textContaining('Tuesday 8 December'), findsOneWidget);
    expect(find.textContaining(PlusConfig.monthlyPrice), findsOneWidget);
  });

  testWidgets('reminder is hidden when Plus is switched off', (t) async {
    await prefs.setBool('plus_active', true);
    await prefs.setInt('plus_trial_start', start.millisecondsSinceEpoch);
    await t.pumpApp(scope(
        TrialReminderCard(now: start.add(const Duration(days: 4))),
        enabled: false));
    expect(find.text(PlusStrings.manage), findsNothing);
  });
}
