import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';

/// A floating glass pill for action bars (chapter nav, verse actions, hymn
/// actions). Glass lives on the nav and action layer only: place it as a
/// sibling of the page content in a Stack, never inside a clipping parent.
class LumGlassBar extends StatelessWidget {
  const LumGlassBar({
    super.key,
    required this.child,
    this.height = 56,
    this.padding = const EdgeInsets.symmetric(horizontal: LumSpace.sm),
  });

  final Widget child;
  final double height;
  final EdgeInsetsGeometry padding;

  static const double radius = 32;

  @override
  Widget build(BuildContext context) {
    final lum = context.lum;
    final shape = BorderRadius.circular(radius);
    return Container(
      constraints: BoxConstraints(minHeight: height),
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
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
