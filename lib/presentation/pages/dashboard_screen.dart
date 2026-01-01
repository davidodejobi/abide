import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:openbaptisthymnal/presentation/pages/tabs/home_tab_screen.dart';

import '../../providers/bottom_nav_provider.dart';
import '../widgets/bottom_nav_bar/bottom_nav_bar.dart';
import 'tabs/favorites_tab_screen.dart';
import 'tabs/settings_tab_screen.dart';

@RoutePage()
class DashboardScreen extends HookConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavProvider);

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: IndexedStack(
              index: currentIndex,
              children: const [
                HomeTabScreen(),
                FavoritesTabScreen(),
                SettingsTabScreen(),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomNavigation(
              currentIndex: currentIndex,
              onTabSelected: (index) {
                ref.read(bottomNavProvider.notifier).state = index;
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Extracted widget to prevent unnecessary rebuilds
/// of the expensive liquid glass renderer
class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.currentIndex,
    required this.onTabSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: AdaptiveBottomNavBar(
        fake: false,
        showIndicator: true,
        indicatorColor: colorScheme.primary,
        glassSettings: const LiquidGlassSettings(
          ambientStrength: 0.2,
        ),
        tabs: const [
          AdaptiveBottomNavTab(
            label: 'Home',
            icon: CupertinoIcons.home,
          ),
          AdaptiveBottomNavTab(
            label: 'Favorites',
            icon: CupertinoIcons.heart,
            selectedIcon: CupertinoIcons.heart_fill,
          ),
          AdaptiveBottomNavTab(
            label: 'Settings',
            icon: CupertinoIcons.settings,
          ),
        ],
        selectedIndex: currentIndex,
        onTabSelected: onTabSelected,
      ),
    );
  }
}
