import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/features/plus/data/purchase_service.dart';
import 'package:openbaptisthymnal/features/plus/domain/plus_rules.dart';
import 'package:openbaptisthymnal/features/plus/plus_config.dart';
import 'package:openbaptisthymnal/features/plus/providers/plus_providers.dart';
import 'package:openbaptisthymnal/features/plus/ui/plus_gate.dart';
import 'package:openbaptisthymnal/features/plus/ui/trial_reminder_card.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/screens/plus_offer_screen.dart';
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
      expect(showOnboardingOffer(e), isTrue);
      for (final f in PlusFeature.values) {
        expect(isGated(e, f), isTrue);
      }
    });

    test('Plus readers are not offered or gated', () {
      const e = Entitlement(isPlus: true);
      expect(showOnboardingOffer(e), isFalse);
      expect(isGated(e, PlusFeature.sync), isFalse);
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

    test('no gated feature is core reading content', () {
      final all = PlusFeature.values.map((f) => f.title.toLowerCase()).join(' ');
      expect(all.contains('plan'), isFalse);
    });
  });

  ProviderScope scope(Widget child) => ProviderScope(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        purchaseServiceProvider.overrideWithValue(
            const FakePurchaseService(delay: Duration(milliseconds: 10))),
      ], child: child);

  Widget gateButton() => Consumer(
        builder: (context, ref, _) => TextButton(
          onPressed: () => requirePlus(context, ref, PlusFeature.sync),
          child: const Text('open'),
        ),
      );

  testWidgets('gate sheet opens for free readers, Not now closes it',
      (t) async {
    await t.pumpApp(scope(gateButton()));
    await t.tap(find.text('open'));
    await t.pump(const Duration(seconds: 1));
    expect(find.text(PlusFeature.sync.title), findsOneWidget);
    expect(find.text(PlusStrings.startTrial), findsOneWidget);
    await t.tap(find.text(PlusStrings.notNow));
    await t.pump(const Duration(seconds: 1));
    expect(find.text(PlusStrings.notNow), findsNothing);
  });

  testWidgets('gate does not open for Plus readers', (t) async {
    await prefs.setBool('plus_active', true);
    await t.pumpApp(scope(gateButton()));
    await t.tap(find.text('open'));
    await t.pump(const Duration(seconds: 1));
    expect(find.text(PlusStrings.startTrial), findsNothing);
  });

  testWidgets('starting the trial from the sheet grants Plus', (t) async {
    await t.pumpApp(scope(gateButton()));
    await t.tap(find.text('open'));
    await t.pump(const Duration(seconds: 1));
    await t.tap(find.text(PlusStrings.startTrial));
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(seconds: 1));
    final c = ProviderScope.containerOf(t.element(find.text('open')));
    expect(c.read(plusProvider).isPlus, isTrue);
    expect(c.read(plusProvider).trialStartedAt, isNotNull);
  });

  testWidgets('onboarding offer: Continue free skips, trial grants', (t) async {
    var done = 0;
    await t.pumpApp(scope(PlusOfferScreen(onDone: () => done++)));
    await t.tap(find.text(PlusStrings.continueFree));
    await t.pump();
    expect(done, 1);
    final c = ProviderScope.containerOf(t.element(find.byType(PlusOfferScreen)));
    expect(c.read(plusProvider).isPlus, isFalse);

    await t.tap(find.text(PlusStrings.startTrial));
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(seconds: 1));
    expect(done, 2);
    expect(c.read(plusProvider).isPlus, isTrue);
  });

  testWidgets('reminder card shows on day 5 only, with charge date',
      (t) async {
    await prefs.setBool('plus_active', true);
    await prefs.setInt('plus_trial_start', start.millisecondsSinceEpoch);
    await t.pumpApp(
        scope(TrialReminderCard(now: start.add(const Duration(days: 2)))));
    expect(find.text(PlusStrings.manage), findsNothing);
    await t.pumpApp(
        scope(TrialReminderCard(now: start.add(const Duration(days: 4)))));
    expect(find.text(PlusStrings.manage), findsOneWidget);
    expect(find.textContaining('8/12/2026'), findsOneWidget);
  });
}
