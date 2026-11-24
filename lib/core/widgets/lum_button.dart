import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';

enum LumButtonKind { primary, gold, secondary }

/// Chunky button (Figma `Chunky button`): a 60pt face on a 4pt darker lip that
/// the face sinks into while pressed. Primary is ink, gold is for "Mark read"
/// moments, secondary is the quiet variant.
class LumButton extends StatefulWidget {
  const LumButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = LumButtonKind.primary,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final LumButtonKind kind;
  final Widget? icon;

  static const double faceHeight = 60;
  static const double lip = 4;

  @override
  State<LumButton> createState() => _LumButtonState();
}

class _LumButtonState extends State<LumButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    final (lipColor, face, fg) = switch (widget.kind) {
      LumButtonKind.primary => (
          c.buttonPrimaryLip,
          BoxDecoration(color: c.bgPrimary),
          c.textOnPrimary,
        ),
      LumButtonKind.gold => (
          c.buttonGoldLip,
          BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [c.buttonGoldTop, c.buttonGoldBottom],
            ),
          ),
          c.buttonOnGold,
        ),
      LumButtonKind.secondary => (
          c.buttonSecondaryLip,
          BoxDecoration(color: c.buttonSecondary),
          c.textPrimary,
        ),
    };
    const radius = BorderRadius.all(Radius.circular(LumRadius.lg));
    final enabled = widget.onPressed != null;
    final sink = _down ? LumButton.lip : 0.0;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      onTap: widget.onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTap: widget.onPressed,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Container(
            constraints: const BoxConstraints(
                minHeight: LumButton.faceHeight + LumButton.lip),
            decoration: BoxDecoration(color: lipColor, borderRadius: radius),
            child: Padding(
              padding: EdgeInsets.only(
                top: sink,
                bottom: LumButton.lip - sink,
              ),
              child: Container(
                decoration: face.copyWith(borderRadius: radius),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      IconTheme(
                        data: IconThemeData(color: fg, size: LumSize.iconSm),
                        child: widget.icon!,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Flexible(
                      child: Text(widget.label,
                          textAlign: TextAlign.center,
                          style: LumText.headline.copyWith(color: fg)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
