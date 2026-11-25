import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';

/// The soft rounded card that groups list rows (Figma grouped list). Rows draw
/// their own hairline; this only owns the surface, border and clip.
class LumGroupCard extends StatelessWidget {
  const LumGroupCard({super.key, required this.child});

  final Widget child;

  static BoxDecoration decoration(LumColors c) => BoxDecoration(
        color: c.bgSurface,
        borderRadius: BorderRadius.circular(LumRadius.xl),
        border: Border.all(color: c.borderSubtle),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: decoration(context.lum),
      child: child,
    );
  }
}
