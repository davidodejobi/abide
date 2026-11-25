import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/core/theme/app_theme.dart';
import 'package:openbaptisthymnal/features/hymn/providers/hymnal_provider.dart';
import 'package:openbaptisthymnal/features/hymn/ui/home_tab_screen.dart';
import 'package:openbaptisthymnal/features/hymn/ui/hymn_detail_page.dart';
import 'package:openbaptisthymnal/features/hymn/ui/hymn_strings.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/hymn_list_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/hymn_harness.dart';
import '../../../support/reader_harness.dart' show appFor, setView, settle;

void main() {
  Future<List<Override>> overrides() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return [
      sharedPreferencesProvider.overrideWithValue(prefs),
      hymnalRepositoryProvider.overrideWithValue(FakeHymnalRepository()),
      languageProvider.overrideWith((ref) => 'en'),
    ];
  }

  const sizes = [
    ('390x844', Size(390, 844), 1.0),
    ('320 wide at 2x text', Size(320, 700), 2.0),
    ('landscape 844x390', Size(844, 390), 1.0),
  ];

  group('Songs list', () {
    for (final (name, size, scale) in sizes) {
      testWidgets('lists hymns with first lines, $name', (t) async {
        setView(t, size);
        await t.pumpWidget(appFor(await overrides(),
            const Scaffold(body: SafeArea(child: HomeTabScreen())),
            scale: scale));
        await settle(t);
        expect(find.text(HymnStrings.songs), findsOneWidget);
        // In landscape the header fills the screen; the list is a scroll away.
        await t.dragUntilVisible(find.text('Holy, Holy, Holy'),
            find.byType(CustomScrollView), const Offset(0, -200));
        expect(find.byType(HymnListTile), findsWidgets);
        expect(t.takeException(), isNull);
      });

      testWidgets('rests the traveller when nothing matches, $name', (t) async {
        setView(t, size);
        await t.pumpWidget(appFor(await overrides(),
            const Scaffold(body: SafeArea(child: HomeTabScreen())),
            theme: AppTheme.darkTheme, scale: scale));
        await settle(t);
        await t.enterText(find.byType(TextField), 'Habakkuk');
        await settle(t);
        await t.dragUntilVisible(find.text(HymnStrings.noResults('Habakkuk')),
            find.byType(CustomScrollView), const Offset(0, -200));
        expect(find.text(HymnStrings.noResults('Habakkuk')), findsOneWidget);
        expect(find.byType(HymnListTile), findsNothing);
        expect(t.takeException(), isNull);
      });
    }

    testWidgets('tapping the heart favourites the hymn', (t) async {
      setView(t, const Size(390, 844));
      final semantics = t.ensureSemantics();
      try {
        await t.pumpWidget(appFor(await overrides(),
            const Scaffold(body: SafeArea(child: HomeTabScreen()))));
        await settle(t);
        await t.tap(find.bySemanticsLabel(HymnStrings.addFavourite).first);
        await settle(t);
        expect(
            find.bySemanticsLabel(HymnStrings.removeFavourite), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    });
  });

  group('Hymn page', () {
    for (final (name, size, scale) in sizes) {
      testWidgets('shows title, meta, stanzas and actions, $name', (t) async {
        setView(t, size);
        await t.pumpWidget(appFor(
            await overrides(), const HymnDetailPage(hymnId: 'hymn_0001'),
            scale: scale));
        await settle(t);
        expect(find.text('Holy, Holy, Holy'), findsOneWidget);
        expect(
            find.text('${HymnStrings.stanzas(2)} · English'), findsOneWidget);
        expect(find.bySemanticsLabel(HymnStrings.splitView), findsOneWidget);
        expect(find.bySemanticsLabel(HymnStrings.share), findsOneWidget);
        expect(t.takeException(), isNull);
      });

      testWidgets('split view opens the second language, $name', (t) async {
        setView(t, size);
        await t.pumpWidget(appFor(
            await overrides(), const HymnDetailPage(hymnId: 'hymn_0001'),
            theme: AppTheme.darkTheme, scale: scale));
        await settle(t);
        await t.tap(find.bySemanticsLabel(HymnStrings.splitView));
        await settle(t);
        expect(find.text('Mímọ́, Holy, Holy, Holy'), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    }
  });
}
