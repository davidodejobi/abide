import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/utils/extensions/string_extensions.dart';
import 'package:vector_graphics/vector_graphics_compat.dart';

/// Glass tab bar (Figma "Glass tab bar", 813:621). Same look on iOS and Android.
/// Glass lives on this nav layer only: place it as a sibling of the page content,
/// never inside a clipping parent.
///
/// Icons resolve from the lowercased label ('Today' -> today.svg / today_fill.svg).
class GlassTabBar extends StatelessWidget {
  const GlassTabBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  static const _radius = 32.0;
  static const _itemHeight = 52.0;

  @override
  Widget build(BuildContext context) {
    final lum = context.lum;
    final duration = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : LumMotion.fast;
    final shape = BorderRadius.circular(_radius);

    return Container(
      height: LumSize.tabBar,
      decoration: BoxDecoration(
        borderRadius: shape,
        // Shadow is drawn outside the blur clip so it is not cut off.
        boxShadow: [
          BoxShadow(
            color: lum.glassEdgeShadow,
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: lum.glassFill,
              borderRadius: shape,
              border: Border.all(color: lum.glassStroke),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: _TabItem(
                        label: labels[i],
                        selected: i == selectedIndex,
                        duration: duration,
                        onTap: () => onTabSelected(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.selected,
    required this.duration,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lum = context.lum;
    final color = selected ? lum.textPrimary : lum.textSecondary;
    final icon = label.toLowerCase();

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: duration,
            height: GlassTabBar._itemHeight,
            constraints: const BoxConstraints(
              minWidth: LumSize.touchTarget,
              maxWidth: 66,
            ),
            decoration: BoxDecoration(
              color: selected ? lum.tabActive : Colors.transparent,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                VectorGraphic(
                  loader: AssetBytesLoader(
                    (selected ? '${icon}_fill' : icon).iconSvg,
                  ),
                  // Sized here: the SVGs are authored on different grids.
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  textScaler: MediaQuery.textScalerOf(context)
                      .clamp(maxScaleFactor: 1.3),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: LumText.caption.copyWith(
                    fontSize: 11,
                    height: 1.2,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
