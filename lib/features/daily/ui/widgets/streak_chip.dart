import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';

import '../daily_strings.dart';
import 'lamp_icon.dart';

/// Lamp + day count pill on the road hero (Figma `Streak chip`). Tapping opens
/// the streak page.
class StreakChip extends StatelessWidget {
  const StreakChip({super.key, required this.days, required this.onTap});

  final int days;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Semantics(
      button: true,
      label: DailyStrings.streakChipSemantics(days),
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: LumSize.touchTarget),
          child: Center(
            widthFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.chip,
                borderRadius: BorderRadius.circular(LumRadius.full),
                border: Border.all(color: c.borderSubtle),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: LumSpace.lg, vertical: LumSpace.sm),
                // Small chip beside the greeting: capped so it never squeezes
                // the title off the row at large text sizes.
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.3,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LampIcon(size: 24),
                      const SizedBox(width: LumSpace.sm),
                      Text('$days',
                          style: LumText.roadDisplayStat28
                              .copyWith(fontSize: 22, color: c.textPrimary)),
                      const SizedBox(width: LumSpace.xs),
                      Text(DailyStrings.streakDays(days),
                          style: LumText.subheadline
                              .copyWith(color: c.textSecondary)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
