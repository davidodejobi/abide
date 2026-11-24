import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/features/bible/ui/bible_reader_page.dart';
import 'package:openbaptisthymnal/features/bible/ui/bible_tab_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression test for a bug that stranded users with no bottom navigation.
///
/// [BibleReaderPage] renders the very same [BibleTabScreen] widget as the
/// dashboard's Bible tab, but as a *pushed full-screen route*. That widget hides
/// the app's floating nav bar while you scroll down, which is right when it owns
/// the bar and wrong when it does not: scrolling in the pushed reader hid the
/// dashboard's nav bar, and it was still hidden after popping back -- with
/// nothing on screen to explain where it went, and no way to restore it but to
/// find the Bible tab and scroll up.
///
/// Every "Continue reading" tap on the Today tab pushes this route.
void main() {
  late SharedPreferences prefs;

  setUp(() async {
    // sharedPreferencesProvider throws until main.dart overrides it, and the
    // reader reads settings (font scale, reading position) on the way up.
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('Given the Bible reader is opened as a pushed page', () {
    group('When it builds', () {
      testWidgets('Then it must not control the app nav bar', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: const MaterialApp(home: BibleReaderPage()),
          ),
        );

        final reader = tester.widget<BibleTabScreen>(
          find.byType(BibleTabScreen),
        );

        expect(
          reader.controlsAppNav,
          isFalse,
          reason: 'a pushed route has no nav bar of its own; hiding the '
              "dashboard's from here strands the user",
        );
      });
    });
  });

  group('Given the Bible tab inside the dashboard', () {
    group('When it is built', () {
      test('Then it does control the app nav bar by default', () {
        // The auto-hide behaviour is wanted there -- it is the tab that actually
        // sits behind the bar.
        expect(const BibleTabScreen().controlsAppNav, isTrue);
      });
    });
  });
}
