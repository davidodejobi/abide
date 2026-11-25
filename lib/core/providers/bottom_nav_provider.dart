import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that tracks the currently selected bottom navigation tab index
final bottomNavProvider = StateProvider<int>((ref) => 0);

/// Whether the floating glass bottom nav bar is visible. Reading surfaces
/// (e.g. the Bible tab) set this false while the user scrolls down and true
/// again on scroll up, so chrome gets out of the way during immersive reading.
final bottomNavVisibleProvider = StateProvider<bool>((ref) => true);

/// The bottom navigation tabs.
///
/// Today lands first, and is therefore the tab the app opens on
/// ([bottomNavProvider] defaults to 0). That is the point of the whole feature:
/// a streak nobody sees cannot bring anyone back, so it greets you rather than
/// waiting to be found.
///
/// The nav bar labels come from this enum; `IndexedStack.children` in
/// `dashboard_screen.dart` is still a hand-synced list at the same ordinals.
/// The nav bar resolves each icon from the *lowercased
/// label* (`'Today'` -> `assets/images/icons/today.svg` + `today_fill.svg`).
/// A missing SVG throws at runtime, not at build.
enum BottomNavTab {
  today(0, 'Today'),
  bible(1, 'Bible'),
  songs(2, 'Songs'),
  notes(3, 'Notes'),
  settings(4, 'You');

  const BottomNavTab(this.tabIndex, this.label);

  final int tabIndex;
  final String label;

  static BottomNavTab fromIndex(int index) {
    return BottomNavTab.values.firstWhere(
      (tab) => tab.tabIndex == index,
      orElse: () => BottomNavTab.today,
    );
  }
}
