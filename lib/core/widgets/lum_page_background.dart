import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';

/// Page colour plus the two soft glows (top-left, bottom-right) from the
/// Lumway page frames. Put it behind page content; it paints no glass.
class LumPageBackground extends StatelessWidget {
  const LumPageBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final lum = context.lum;
    return DecoratedBox(
      decoration: BoxDecoration(color: lum.bgPage),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _Glow(alignment: Alignment.topLeft, color: lum.glowPageTl),
          _Glow(alignment: Alignment.bottomRight, color: lum.glowPageBr),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.alignment, required this.color});

  final Alignment alignment;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: alignment,
          radius: 0.9,
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
