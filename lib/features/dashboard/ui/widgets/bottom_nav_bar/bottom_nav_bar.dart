// ignore_for_file: deprecated_member_use

import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import 'bottom_nav_bar_android.dart';
import 'bottom_nav_bar_ios.dart';

/// Platform-adaptive bottom navigation bar
/// Uses iOS liquid glass design on iOS and Material Design 3 on Android
class AdaptiveBottomNavBar extends StatelessWidget {
  const AdaptiveBottomNavBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.extraButton,
    this.spacing = 8,
    this.horizontalPadding = 20,
    this.bottomPadding = 12,
    this.barHeight = 72,
    this.glassSettings,
    this.showIndicator = true,
    this.indicatorColor,
    this.fake = false,
  });

  final List<AdaptiveBottomNavTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final LiquidGlassBottomBarExtraButton? extraButton;
  final double spacing;
  final double horizontalPadding;
  final double bottomPadding;
  final double barHeight;
  final LiquidGlassSettings? glassSettings;
  final bool showIndicator;
  final Color? indicatorColor;
  final bool fake;

  @override
  Widget build(BuildContext context) {
    // Use platform-specific implementation
    if (!Platform.isAndroid) {
      return MaterialBottomNavBar(
        tabs: tabs
            .map((tab) => MaterialBottomNavTab(
                  label: tab.label,
                  icon: tab.icon,
                  selectedIcon: tab.selectedIcon,
                ))
            .toList(),
        selectedIndex: selectedIndex,
        onTabSelected: onTabSelected,
        height: barHeight,
        selectedItemColor: indicatorColor,
      );
    } else {
      // iOS implementation
      return LiquidGlassBottomBar(
        tabs: tabs
            .map((tab) => LiquidGlassBottomBarTab(
                  label: tab.label,
                  icon: tab.icon,
                  selectedIcon: tab.selectedIcon,
                  glowColor: tab.glowColor,
                ))
            .toList(),
        selectedIndex: selectedIndex,
        onTabSelected: onTabSelected,
        extraButton: extraButton,
        spacing: spacing,
        horizontalPadding: horizontalPadding,
        bottomPadding: bottomPadding,
        barHeight: barHeight,
        glassSettings: glassSettings,
        showIndicator: showIndicator,
        indicatorColor: indicatorColor,
        fake: fake,
      );
    }
  }
}

/// Unified tab model that works for both platforms
class AdaptiveBottomNavTab {
  const AdaptiveBottomNavTab({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.glowColor,
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final Color? glowColor;
}
