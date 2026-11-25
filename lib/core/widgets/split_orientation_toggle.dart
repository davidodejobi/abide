import 'package:material_ui/material_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/widgets/split_pane.dart';

/// Small segmented control to flip a [SplitPane] between vertical and
/// horizontal orientations. Each segment is a 48pt touch target.
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
    final c = context.lum;

    Widget segment({
      required SplitOrientation value,
      required IconData icon,
      required String tooltip,
    }) {
      final selected = orientation == value;
      return Semantics(
        button: true,
        selected: selected,
        label: tooltip,
        excludeSemantics: true,
        onTap: () => onChanged(value),
        child: Tooltip(
          message: tooltip,
          child: GestureDetector(
            onTap: () => onChanged(value),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: LumMotion.fast,
              width: LumSize.touchTarget,
              height: LumSize.touchTarget - 8,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? c.bgPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(LumRadius.full),
              ),
              child: Icon(icon,
                  size: 20, color: selected ? c.textOnPrimary : c.textPrimary),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(LumSpace.xs),
      decoration: BoxDecoration(
        color: c.bgSurface,
        borderRadius: BorderRadius.circular(LumRadius.full),
        border: Border.all(color: c.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          segment(
            value: SplitOrientation.vertical,
            icon: PhosphorIcons.columns(),
            tooltip: 'Side by side',
          ),
          segment(
            value: SplitOrientation.horizontal,
            icon: PhosphorIcons.rows(),
            tooltip: 'Stacked',
          ),
        ],
      ),
    );
  }
}
