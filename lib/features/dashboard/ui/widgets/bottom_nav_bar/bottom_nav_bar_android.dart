import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/utils/extensions/context_extensions.dart';
import 'package:openbaptisthymnal/core/utils/extensions/string_extensions.dart';
import 'package:vector_graphics/vector_graphics_compat.dart';

/// Android Material Design 3 Bottom Navigation Bar
/// Features elevated surface with shadow and proper Material theming
class MaterialBottomNavBar extends StatelessWidget {
  const MaterialBottomNavBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation = 8.0,
    this.height = 80.0,
  });

  final List<MaterialBottomNavTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double elevation;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Material 3 color defaults
    final bgColor = backgroundColor ?? colorScheme.surface;
    final selectedColor = selectedItemColor ?? colorScheme.primary;
    final unselectedColor = unselectedItemColor ?? colorScheme.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: 12,
        top: 0,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        color: bgColor,
        boxShadow: [
          // Primary elevated shadow - Material Design 3 elevation level 3
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 0),
            spreadRadius: 2,
          ),
          // Ambient shadow
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(10, -4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < tabs.length; i++)
              Expanded(
                child: _MaterialNavItem(
                  tab: tabs[i],
                  selected: selectedIndex == i,
                  selectedColor: selectedColor,
                  unselectedColor: unselectedColor,
                  onTap: () => onTabSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MaterialBottomNavTab {
  const MaterialBottomNavTab({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.badge,
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final String? badge;
}

class _MaterialNavItem extends StatelessWidget {
  const _MaterialNavItem({
    required this.tab,
    required this.selected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  final MaterialBottomNavTab tab;
  final bool selected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String label = tab.label.toLowerCase();
    final color = selected ? selectedColor : unselectedColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: selected
              ? selectedColor.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(36),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: VectorGraphic(
                    loader: AssetBytesLoader(
                      (selected ? '${label}_fill' : label).iconSvg,
                    ),
                    key: ValueKey(selected),
                    // Sized here, not from the SVG: the icons are authored on
                    // different grids (24/29/256) so their intrinsic sizes
                    // disagree.
                    width: 26,
                    height: 26,
                    colorFilter: ColorFilter.mode(
                      color,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                if (tab.badge != null)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          tab.badge ?? '00',
                          style: context.textStyles.small.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: context.textStyles.caption.copyWith(
                color: color,
              ),
              child: Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
