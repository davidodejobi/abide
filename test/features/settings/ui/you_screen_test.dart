import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/audio/audio_quality.dart';
import 'package:openbaptisthymnal/core/audio/audio_quality_provider.dart';
import 'package:openbaptisthymnal/core/preferences/linking_preferences.dart';
import 'package:openbaptisthymnal/core/providers/app_info_provider.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/core/theme/app_theme.dart';
import 'package:openbaptisthymnal/core/theme/theme_provider.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_edition.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';
import 'package:openbaptisthymnal/features/settings/ui/settings_tab_screen.dart';
import 'package:openbaptisthymnal/features/settings/ui/you_strings.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pump(WidgetTester tester,
    {ThemeData? theme, double scale = 1}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    appVersionProvider.overrideWith((_) async => '1.2.3'),
    bibleEditionsProvider.overrideWithValue(const <BibleEdition>[]),
  ]);
  addTearDown(container.dispose);
  tester.view.physicalSize = const Size(390 * 3, 1400 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: const Scaffold(body: SettingsTabScreen()),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 100));
  return container;
}

void main() {
  testWidgets('shows the You sections and version', (tester) async {
    await _pump(tester);
    expect(find.text(YouStrings.title), findsOneWidget);
    expect(find.text(YouStrings.appearance.toUpperCase()), findsOneWidget);
    expect(find.text(YouStrings.linkBible), findsOneWidget);
    expect(find.text('Version 1.2.3'), findsOneWidget);
    expect(find.text('Settings'), findsNothing);
  });

  testWidgets('theme chip writes the theme provider', (tester) async {
    final container = await _pump(tester);
    await tester.tap(find.text(YouStrings.dark));
    await tester.pump();
    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  testWidgets('quality chip writes the audio quality provider', (tester) async {
    final container = await _pump(tester);
    await tester.tap(find.text(AudioQuality.high.label));
    await tester.pump();
    expect(container.read(audioQualityProvider), AudioQuality.high);
  });

  testWidgets('hymnal link picker saves the choice', (tester) async {
    final container = await _pump(tester);
    await tester.tap(find.text(YouStrings.linkHymnal));
    await tester.pumpAndSettle();
    await tester.tap(find.text(YouStrings.yoruba));
    await tester.pumpAndSettle();
    expect(
        container.read(linkingPreferencesProvider).defaultHymnEditionId, 'yo');
    expect(container.read(storageServiceProvider), isNotNull);
  });

  testWidgets('dark theme at large text scale does not overflow',
      (tester) async {
    await _pump(tester, theme: AppTheme.darkTheme, scale: 2);
    expect(tester.takeException(), isNull);
  });
}
