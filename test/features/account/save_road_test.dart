import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/providers/app_info_provider.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/core/theme/app_theme.dart';
import 'package:openbaptisthymnal/features/account/data/fake_auth_repository.dart';
import 'package:openbaptisthymnal/features/account/domain/auth_repository.dart';
import 'package:openbaptisthymnal/features/account/domain/save_road_rule.dart';
import 'package:openbaptisthymnal/features/account/providers/account_providers.dart';
import 'package:openbaptisthymnal/features/account/ui/account_strings.dart';
import 'package:openbaptisthymnal/features/account/ui/save_road_sheet.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';
import 'package:openbaptisthymnal/features/settings/ui/settings_tab_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _delay = Duration(milliseconds: 100);

Future<(ProviderContainer, FakeAuthRepository)> _pump(
    WidgetTester tester, Widget home) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final repo = FakeAuthRepository(delay: _delay);
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    authRepositoryProvider.overrideWithValue(repo),
    appVersionProvider.overrideWith((_) async => '1.0.0'),
    bibleEditionsProvider.overrideWithValue(const []),
  ]);
  addTearDown(container.dispose);
  tester.view.physicalSize = const Size(1170, 4200);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(theme: AppTheme.lightTheme, home: Scaffold(body: home)),
  ));
  await tester.pump(const Duration(milliseconds: 100));
  return (container, repo);
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.text(AccountStrings.saveRow));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _sendEmail(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField), 'a@b.co');
  await tester.pump();
  await tester.tap(find.text(AccountStrings.sendCode));
  await tester.pump(_delay);
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('shouldPromptSaveRoad (day-3 rule)', () {
    bool rule({int? prev, required int days, bool loaded = true, bool saved = false, bool seen = false}) =>
        shouldPromptSaveRoad(
            previousDays: prev, days: days, accountLoaded: loaded, saved: saved, alreadyPrompted: seen);

    test('fires when the third day is completed', () {
      expect(rule(prev: 2, days: 3), isTrue);
    });
    test('not before day 3, not on first load, not later', () {
      expect(rule(prev: 1, days: 2), isFalse);
      expect(rule(prev: null, days: 5), isFalse);
      expect(rule(prev: 3, days: 4), isFalse);
      expect(rule(prev: 0, days: 3), isFalse); // sync jump
      expect(rule(prev: 2, days: 3, loaded: false), isFalse);
    });
    test('never for a saved reader or after it was shown once', () {
      expect(rule(prev: 2, days: 3, saved: true), isFalse);
      expect(rule(prev: 2, days: 3, seen: true), isFalse);
    });
  });

  testWidgets('You tab shows Save your road, then Saved as after saving',
      (tester) async {
    await _pump(tester, const SettingsTabScreen());
    expect(find.text(AccountStrings.saveRow), findsOneWidget);

    await _openSheet(tester);
    await _sendEmail(tester);
    expect(find.text(AccountStrings.codeLabel), findsOneWidget);

    // Paste-style entry: non-digits are dropped, the sixth digit auto-verifies.
    await tester.enterText(find.byType(TextField), '123 456');
    await tester.pump(_delay);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(AccountStrings.successTitle), findsOneWidget);

    await tester.tap(find.text(AccountStrings.done));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(AccountStrings.savedAs('a@b.co')), findsOneWidget);
    expect(find.text(AccountStrings.saveRow), findsNothing);
  });

  testWidgets('wrong code shows an error and stays on the code step',
      (tester) async {
    final (_, repo) = await _pump(tester, const SettingsTabScreen());
    await _openSheet(tester);
    await _sendEmail(tester);

    repo.nextFailure = const AuthFailure(AuthFailureKind.wrongCode);
    await tester.enterText(find.byType(TextField), '111111');
    await tester.pump(_delay);
    await tester.pump();
    expect(find.text(AccountStrings.error(AuthFailureKind.wrongCode)),
        findsOneWidget);
    expect(find.text(AccountStrings.successTitle), findsNothing);
  });

  testWidgets('no network on send shows an error, resend waits on a timer',
      (tester) async {
    final (_, repo) = await _pump(tester, const SettingsTabScreen());
    await _openSheet(tester);

    repo.nextFailure = const AuthFailure(AuthFailureKind.network);
    await _sendEmail(tester);
    expect(find.text(AccountStrings.error(AuthFailureKind.network)),
        findsOneWidget);

    await _sendEmail(tester); // retry succeeds
    expect(find.text(AccountStrings.resendIn(30)), findsOneWidget);
    await tester.pump(const Duration(seconds: 30));
    expect(find.text(AccountStrings.resend), findsOneWidget);
  });

  testWidgets('Not now closes the sheet without saving', (tester) async {
    await _pump(tester, const SettingsTabScreen());
    await _openSheet(tester);
    await tester.tap(find.text(AccountStrings.notNow));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SaveRoadSheet), findsNothing);
    expect(find.text(AccountStrings.saveRow), findsOneWidget);
  });

  testWidgets('prompted flag persists once marked', (tester) async {
    final (container, _) = await _pump(tester, const SizedBox());
    expect(container.read(saveRoadPromptedProvider), isFalse);
    container.read(saveRoadPromptedProvider.notifier).markShown();
    expect(container.read(saveRoadPromptedProvider), isTrue);
    expect(container.read(sharedPreferencesProvider).getBool('save_road_prompted'),
        isTrue);
  });
}
