import 'dart:ui';

import 'package:flutter/physics.dart';

import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/utils/extensions/string_extensions.dart';
import 'package:vector_graphics/vector_graphics_compat.dart';

/// Glass tab bar (Figma "Glass tab bar", 813:621). Same look on iOS and Android.
/// Glass lives on this nav layer only: place it as a sibling of the page content,
/// never inside a clipping parent.
///
/// Icons resolve from the lowercased label ('Today' -> today.svg / today_fill.svg).
class GlassTabBar extends StatefulWidget {
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
  static const _hPad = 6.0;

  /// Figma `motion/spring/bouncy` (260/18); the token file only documents it.
  static const _spring = SpringDescription(
    mass: 1,
    stiffness: 260,
    damping: 18,
  );

  @override
  State<GlassTabBar> createState() => _GlassTabBarState();
}

class _GlassTabBarState extends State<GlassTabBar>
    with SingleTickerProviderStateMixin {
  /// Fractional tab position; unbounded so the spring may overshoot.
  late final AnimationController _pos;

  @override
  void initState() {
    super.initState();
    _pos = AnimationController.unbounded(
      vsync: this,
      value: widget.selectedIndex.toDouble(),
    );
  }

  @override
  void didUpdateWidget(GlassTabBar old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex == widget.selectedIndex) return;
    final target = widget.selectedIndex.toDouble();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pos.value = target;
    } else {
      _pos.animateWith(SpringSimulation(
        GlassTabBar._spring,
        _pos.value,
        target,
        _pos.velocity,
      ));
    }
  }

  @override
  void dispose() {
    _pos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lum = context.lum;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final shape = BorderRadius.circular(GlassTabBar._radius);
    final n = widget.labels.length;

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
              padding:
                  const EdgeInsets.symmetric(horizontal: GlassTabBar._hPad),
              child: LayoutBuilder(
                builder: (context, box) {
                  final itemW = box.maxWidth / n;
                  return Stack(
                    alignment: Alignment.center,
                    // Spring overshoot may leave the cell; the bar's ClipRRect trims it.
                    clipBehavior: Clip.none,
                    children: [
                      // Selection indicator, behind the icons.
                      if (reduce)
                        Positioned(
                          left: widget.selectedIndex * itemW,
                          width: itemW,
                          top: 0,
                          bottom: 0,
                          child: AnimatedSwitcher(
                            duration: LumMotion.fast,
                            child: _GlassPill(
                              key: ValueKey(widget.selectedIndex),
                              itemWidth: itemW,
                            ),
                          ),
                        )
                      else
                        AnimatedBuilder(
                          animation: _pos,
                          builder: (context, _) {
                            // Stretch along the direction of travel, squash a hair.
                            final v = _pos.velocity.abs();
                            final stretch = (v * 3).clamp(0.0, 24.0);
                            final squash = (v * 0.35).clamp(0.0, 3.0);
                            return Positioned(
                              left: _pos.value * itemW - stretch / 2,
                              width: itemW + stretch,
                              top: squash / 2,
                              bottom: squash / 2,
                              child: _GlassPill(itemWidth: itemW),
                            );
                          },
                        ),
                      Row(
                        children: [
                          for (var i = 0; i < n; i++)
                            Expanded(
                              child: _TabItem(
                                label: widget.labels[i],
                                selected: i == widget.selectedIndex,
                                onTap: () => widget.onTabSelected(i),
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The liquid-glass selection capsule: blur, tint, specular top highlight,
/// light-top/dark-bottom hairline, soft shadow. It fills the Positioned slot
/// it is given horizontally (item width plus stretch) and is vertically
/// inset to the item height.
class _GlassPill extends StatelessWidget {
  const _GlassPill({super.key, required this.itemWidth});

  final double itemWidth;

  @override
  Widget build(BuildContext context) {
    final lum = context.lum;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final shape = BorderRadius.circular(GlassTabBar._itemHeight / 2);
    // Slots hand us their full height; centre a 52pt capsule (66 max wide).
    return Center(
      child: LayoutBuilder(builder: (context, box) {
        // 66pt cap (the item column) plus whatever stretch the slot adds.
        final base = itemWidth - 4 < 66 ? itemWidth - 4 : 66.0;
        final w = base + (box.maxWidth - itemWidth).clamp(0.0, 40.0);
        return Container(
          width: w,
          height: GlassTabBar._itemHeight,
          decoration: BoxDecoration(
            borderRadius: shape,
            boxShadow: [
              BoxShadow(
                color:
                    lum.glassEdgeShadow.withValues(alpha: dark ? 0.30 : 0.07),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: shape,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: CustomPaint(
                painter: _PillPainter(tint: lum.tabActive, dark: dark),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _PillPainter extends CustomPainter {
  const _PillPainter({required this.tint, required this.dark});

  final Color tint;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(size.height / 2));

    // Body: token tint, then a vertical sheen (bright top, clear lower half).
    canvas.drawRRect(
      rr,
      Paint()..color = tint.withValues(alpha: tint.a * (dark ? 1 : 0.55)),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: dark ? 0.20 : 0.75),
            Colors.white.withValues(alpha: dark ? 0.04 : 0.20),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(rect),
    );

    // Inner hairline: light on top, darker on the bottom edge.
    canvas.drawRRect(
      rr.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: dark ? 0.45 : 0.95),
            Colors.white.withValues(alpha: dark ? 0.08 : 0.30),
            Colors.black.withValues(alpha: dark ? 0.35 : 0.10),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_PillPainter old) => old.tint != tint || old.dark != dark;
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
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
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: LumSize.touchTarget,
              minHeight: GlassTabBar._itemHeight,
              maxWidth: 66,
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
