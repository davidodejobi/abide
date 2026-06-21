import 'package:flutter/material.dart';

/// Orientation of a [SplitPane].
enum SplitOrientation {
  /// Two panes laid out left/right.
  vertical,

  /// Two panes laid out top/bottom.
  horizontal,
}

/// A 50/50 two-pane container that animates between vertical (Row) and
/// horizontal (Column) orientations.
///
/// Pane content is provided by the caller — this widget only owns layout.
/// A thin divider sits between the panes; in v1 it's not draggable.
class SplitPane extends StatelessWidget {
  const SplitPane({
    super.key,
    required this.primary,
    required this.secondary,
    required this.orientation,
    this.dividerColor,
    this.dividerThickness = 1,
    this.animationDuration = const Duration(milliseconds: 280),
  });

  final Widget primary;
  final Widget secondary;
  final SplitOrientation orientation;
  final Color? dividerColor;
  final double dividerThickness;
  final Duration animationDuration;

  @override
  Widget build(BuildContext context) {
    final divider = Container(
      color: dividerColor ?? Theme.of(context).dividerColor.withValues(alpha: 0.4),
      width: orientation == SplitOrientation.vertical ? dividerThickness : null,
      height: orientation == SplitOrientation.horizontal ? dividerThickness : null,
    );

    final children = <Widget>[
      Expanded(child: primary),
      divider,
      Expanded(child: secondary),
    ];

    return AnimatedSwitcher(
      duration: animationDuration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: orientation == SplitOrientation.vertical
          ? Row(
              key: const ValueKey('split-vertical'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            )
          : Column(
              key: const ValueKey('split-horizontal'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
    );
  }
}
