import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';

/// Pill chip. Selected is the ink pill with a check; unselected is a soft
/// surface pill. 48pt tall so it is a full touch target.
class LumChip extends StatelessWidget {
  const LumChip({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    final fg = selected ? c.textOnPrimary : c.textPrimary;
    final lead = selected ? Icons.check_rounded : icon;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: LumSize.touchTarget),
          padding: const EdgeInsets.symmetric(horizontal: LumSpace.xl - 4),
          decoration: BoxDecoration(
            color: selected ? c.bgPrimary : c.bgSurface,
            borderRadius: BorderRadius.circular(LumRadius.full),
            border: selected ? null : Border.all(color: c.borderSubtle),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (lead != null) ...[
                Icon(lead, size: 18, color: fg),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(label,
                    style: LumText.subheadlineEmphasized.copyWith(color: fg)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
