import 'package:material_ui/material_ui.dart';
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
    {ThemeData? theme,
    double scale = 1,
    Size size = const Size(390, 1400),
    List<BibleEdition> editions = const []}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    appVersionProvider.overrideWith((_) async => '1.2.3'),
    bibleEditionsProvider.overrideWithValue(editions),
  ]);
  addTearDown(container.dispose);
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
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
    expect(find.text(YouStrings.dailyReminder), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Version 1.2.3'), 200);
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
    // Persisted: a fresh container over the same prefs reads it back.
    final fresh = ProviderContainer(overrides: [
      sharedPreferencesProvider
          .overrideWithValue(container.read(sharedPreferencesProvider)),
    ]);
    addTearDown(fresh.dispose);
    expect(fresh.read(storageServiceProvider).getDefaultHymnLinkEdition(), 'yo');
  });

  for (final w in [390.0, 320.0]) {
    testWidgets('large text, ${w.toInt()} wide: whole list lays out',
        (tester) async {
      await _pump(tester,
          theme: AppTheme.darkTheme, scale: 3, size: Size(w, 568));
      await tester.scrollUntilVisible(find.text(YouStrings.terms), 300,
          scrollable: find.byType(Scrollable).first);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Bible picker survives 320x568 at 3x text and saves a pick',
      (tester) async {
    const kjv = BibleEdition(
      id: 'en-kjv',
      languageCode: 'en',
      versionCode: 'kjv',
      displayName: 'King James Version',
      attribution: 'Public Domain',
    );
    final container = await _pump(tester,
        scale: 3, size: const Size(320, 568), editions: const [kjv]);
    await tester.scrollUntilVisible(find.text(YouStrings.linkBible), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text(YouStrings.linkBible));
    await tester.pump();
    await tester.tap(find.text(YouStrings.linkBible));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text(kjv.displayName));
    await tester.pump();
    await tester.tap(find.text(kjv.displayName));
    await tester.pumpAndSettle();
    expect(container.read(linkingPreferencesProvider).defaultBibleEditionId,
        'en-kjv');
  });
}
