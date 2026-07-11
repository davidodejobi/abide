import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/providers/bottom_nav_provider.dart';
import 'package:openbaptisthymnal/core/utils/extensions/string_extensions.dart';

/// The bottom nav bar does not render the `IconData` you hand it. It builds the
/// asset path from the tab's **lowercased label** and loads it with
/// `AssetBytesLoader`, which has no fallback -- so a tab whose SVG is missing
/// throws when the bar first paints. On a device. Not at build time, and not in
/// any test that does not load the real bundle.
///
/// This walks every tab in [BottomNavTab] rather than hardcoding 'today', so the
/// next person to add a tab gets the same protection without thinking about it.
///
/// **Local gotcha, verified the hard way.** `flutter test` stages assets into
/// `build/unit_test_assets/` and does NOT prune that directory, so deleting an
/// icon and re-running still passes locally -- the stale copy is what gets
/// loaded. CI has no `build/` dir, so it catches the real thing. To reproduce a
/// failure yourself: `rm -rf build/unit_test_assets` first.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Given the bottom navigation tabs', () {
    for (final tab in BottomNavTab.values) {
      final name = tab.label.toLowerCase();

      group('When the ${tab.label} tab paints', () {
        test('Then $name.svg and ${name}_fill.svg both load', () async {
          // Resting state.
          await expectLater(
            rootBundle.load(name.iconSvg),
            completes,
            reason: '${tab.label} tab has no ${name.iconSvg}',
          );

          // Selected state. The bar swaps to the _fill variant on tap, so a
          // missing one crashes only once someone touches the tab -- the kind of
          // bug that ships.
          await expectLater(
            rootBundle.load('${name}_fill'.iconSvg),
            completes,
            reason: '${tab.label} tab has no ${'${name}_fill'.iconSvg}',
          );
        });
      });
    }
  });

  group('Given the tab ordinals', () {
    test('Then they run 0..n with no gaps, matching the IndexedStack', () {
      // dashboard_screen.dart keeps two hand-synced lists (IndexedStack children
      // and `tabs:`) that this enum only documents. A gap here means the enum
      // and the screen have already drifted.
      expect(
        BottomNavTab.values.map((t) => t.tabIndex),
        List.generate(BottomNavTab.values.length, (i) => i),
      );
    });

    test('Then Today is first, so the app opens on it', () {
      // bottomNavProvider defaults to 0. A streak nobody sees cannot bring
      // anyone back.
      expect(BottomNavTab.fromIndex(0), BottomNavTab.today);
    });
  });
}
