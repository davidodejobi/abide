import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final colorScheme = Theme.of(context).colorScheme;
    // Responsive sizing: 73% of screen width, clamped between 240-320px
    final navWidth = (screenWidth * 0.73).clamp(240.0, 320.0);
    final navHeight = navWidth * 0.268; // Maintain aspect ratio (~74/276)
    final itemSize = navHeight * 0.70; // Item size relative to nav height

    return Center(
      child: Container(
        width: navWidth,
        height: navHeight,
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(navHeight / 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              isSelected: currentIndex == 0,
              onTap: () => onTap(0),
              size: itemSize,
            ),
            _NavItem(
              icon: Icons.favorite_rounded,
              isSelected: currentIndex == 1,
              onTap: () => onTap(1),
              size: itemSize,
            ),
            _NavItem(
              icon: Icons.settings_rounded,
              isSelected: currentIndex == 2,
              onTap: () => onTap(2),
              size: itemSize,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final double size;

  const _NavItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        splashColor: colorScheme.secondary.withValues(alpha: 0.3),
        highlightColor: colorScheme.secondary.withValues(alpha: 0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.secondary.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(size / 2),
          ),
          child: Icon(
            icon,
            size: size * 0.54, // Icon size relative to item size
            color: isSelected
                ? colorScheme.secondary
                : colorScheme.secondary.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
