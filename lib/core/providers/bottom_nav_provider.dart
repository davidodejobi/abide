import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that tracks the currently selected bottom navigation tab index
final bottomNavProvider = StateProvider<int>((ref) => 0);

/// Enum representing the available bottom navigation tabs.
/// Tablets (notes) is the default landing tab; the old Home/hymn tab is now "Songs".
enum BottomNavTab {
  tablets(0, 'Tablets'),
  songs(1, 'Songs'),
  bible(2, 'Bible'),
  favorites(3, 'Favorites'),
  settings(4, 'Settings');

  const BottomNavTab(this.tabIndex, this.label);

  final int tabIndex;
  final String label;

  static BottomNavTab fromIndex(int index) {
    return BottomNavTab.values.firstWhere(
      (tab) => tab.tabIndex == index,
      orElse: () => BottomNavTab.tablets,
    );
  }
}
