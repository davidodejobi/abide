import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that tracks the currently selected bottom navigation tab index
final bottomNavProvider = StateProvider<int>((ref) => 0);

/// Enum representing the available bottom navigation tabs
enum BottomNavTab {
  home(0, 'Home'),
  favorites(1, 'Favorites'),
  settings(2, 'Settings');

  const BottomNavTab(this.tabIndex, this.label);

  final int tabIndex;
  final String label;

  static BottomNavTab fromIndex(int index) {
    return BottomNavTab.values.firstWhere(
      (tab) => tab.tabIndex == index,
      orElse: () => BottomNavTab.home,
    );
  }
}
