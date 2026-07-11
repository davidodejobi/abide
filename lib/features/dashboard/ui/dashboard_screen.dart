import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:openbaptisthymnal/core/providers/bottom_nav_provider.dart';
import 'package:openbaptisthymnal/features/bible/ui/bible_tab_screen.dart';
import 'package:openbaptisthymnal/features/daily/ui/today_tab_screen.dart';
import 'package:openbaptisthymnal/features/dashboard/ui/widgets/bottom_nav_bar/bottom_nav_bar.dart';
import 'package:openbaptisthymnal/features/hymn/ui/home_tab_screen.dart';
import 'package:openbaptisthymnal/features/tablet/ui/tablets_tab_screen.dart';
import 'package:openbaptisthymnal/features/settings/ui/settings_tab_screen.dart';

@RoutePage()
class DashboardScreen extends HookConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavProvider);
    final navVisible = ref.watch(bottomNavVisibleProvider);

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: IndexedStack(
              index: currentIndex,
              children: const [
                // Order must match `tabs:` in _BottomNavigation below, and
                // BottomNavTab's ordinals. Three lists, hand-synced.
                TodayTabScreen(),
                TabletsTabScreen(),
                HomeTabScreen(),
                BibleTabScreen(),
                SettingsTabScreen(),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSlide(
              offset: navVisible ? Offset.zero : const Offset(0, 1.5),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: IgnorePointer(
                ignoring: !navVisible,
                child: _BottomNavigation(
                  currentIndex: currentIndex,
                  onTabSelected: (index) {
                    ref.read(bottomNavProvider.notifier).state = index;
                  },
                ),
              ),
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
          // The `icon` is never rendered: MaterialBottomNavBar resolves the SVG
          // from the LABEL, lowercased ('Today' -> today.svg / today_fill.svg).
          // It is still required by the constructor, hence the placeholder.
          AdaptiveBottomNavTab(
            label: 'Today',
            icon: CupertinoIcons.sun_max,
            selectedIcon: CupertinoIcons.sun_max_fill,
          ),
          AdaptiveBottomNavTab(
            label: 'Tablets',
            icon: CupertinoIcons.doc_text,
            selectedIcon: CupertinoIcons.doc_text_fill,
          ),
          AdaptiveBottomNavTab(
            label: 'Songs',
            icon: CupertinoIcons.music_note_list,
          ),
          AdaptiveBottomNavTab(
            label: 'Bible',
            icon: CupertinoIcons.book,
            selectedIcon: CupertinoIcons.book_fill,
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
