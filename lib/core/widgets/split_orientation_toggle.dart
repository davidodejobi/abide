import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/app_colors.dart';
import 'package:openbaptisthymnal/core/widgets/split_pane.dart';

/// Small segmented control to flip a [SplitPane] between vertical and
/// horizontal orientations.
class SplitOrientationToggle extends StatelessWidget {
  const SplitOrientationToggle({
    super.key,
    required this.orientation,
    required this.onChanged,
  });

  final SplitOrientation orientation;
  final ValueChanged<SplitOrientation> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.neutral850 : AppColors.secondary50;
    final fg = isDark ? AppColors.neutral100 : AppColors.primaryDark;
    final selectedBg = isDark ? AppColors.neutral700 : Colors.white;

    Widget segment({
      required SplitOrientation value,
      required IconData icon,
      required String tooltip,
    }) {
      final selected = orientation == value;
      return Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: () => onChanged(value),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? selectedBg : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, size: 18, color: fg),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          segment(
            value: SplitOrientation.vertical,
            icon: Icons.vertical_split_rounded,
            tooltip: 'Side by side',
          ),
          segment(
            value: SplitOrientation.horizontal,
            icon: Icons.horizontal_split_rounded,
            tooltip: 'Stacked',
          ),
        ],
      ),
    );
  }
}
