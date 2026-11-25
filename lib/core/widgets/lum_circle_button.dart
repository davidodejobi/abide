import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';

/// A 48pt round icon button on a soft surface (Figma back / text size / heart
/// buttons). [label] is the screen reader name.
class LumCircleButton extends StatelessWidget {
  const LumCircleButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
    this.plain = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  /// Icon colour; defaults to the primary text colour.
  final Color? color;

  /// No surface: the icon alone, for use inside a glass bar.
  final bool plain;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      onTap: onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          width: LumSize.glassButton,
          height: LumSize.glassButton,
          alignment: Alignment.center,
          decoration: plain
              ? null
              : BoxDecoration(
                  color: c.bgSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.borderSubtle),
                ),
          child:
              Icon(icon, size: LumSize.iconMd, color: color ?? c.textPrimary),
        ),
      ),
    );
  }
}
