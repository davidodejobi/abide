import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/widgets/lum_page_background.dart';
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
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: LumPageBackground()),
          SafeArea(
            bottom: false,
            child: IndexedStack(
              index: currentIndex,
              // Order must match `tabs:` in _BottomNavigation below, and
              // BottomNavTab's ordinals. Three lists, hand-synced.
              // TickerMode: IndexedStack keeps hidden tabs mounted with tickers
              // running, so mute every tab but the visible one.
              children: [
                for (final (i, tab) in const [
                  TodayTabScreen(),
                  BibleTabScreen(),
                  HomeTabScreen(),
                  TabletsTabScreen(),
                  SettingsTabScreen(),
                ].indexed)
                  TickerMode(enabled: i == currentIndex, child: tab),
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

/// Extracted so the blur layer only rebuilds when the selection changes.
class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.currentIndex,
    required this.onTabSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: LumSize.screenGutter),
        child: GlassTabBar(
          labels: [for (final t in BottomNavTab.values) t.label],
          selectedIndex: currentIndex,
          onTabSelected: onTabSelected,
        ),
      ),
    );
  }
}
