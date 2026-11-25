import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';

import '../onboarding_strings.dart';

/// The "step road" progress pill (Figma K3): stones on a path, the current one
/// a gold coin, plus "2 of 3" in words. Solid surface, not glass.
class StepRoad extends StatelessWidget {
  const StepRoad({super.key, required this.current, required this.total});

  /// 1-based.
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Semantics(
      label: OnboardingStrings.stepSemantics(current, total),
      excludeSemantics: true,
      child: Container(
        height: LumSize.touchTarget,
        padding: const EdgeInsets.symmetric(horizontal: LumSpace.lg),
        decoration: BoxDecoration(
          color: c.scenePanel,
          borderRadius: BorderRadius.circular(LumRadius.full),
          border: Border.all(color: c.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 1; i <= total; i++) ...[
              if (i > 1)
                Container(
                  width: 14,
                  height: 2,
                  color: i <= current ? c.bgPrimary : c.borderStrong,
                ),
              _Stone(
                done: i < current,
                current: i == current,
              ),
            ],
            const SizedBox(width: LumSpace.md),
            Text(
              OnboardingStrings.stepLabel(current, total).toUpperCase(),
              style: LumText.roadLabelCaps11.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stone extends StatelessWidget {
  const _Stone({required this.done, required this.current});

  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    final size = current ? 18.0 : 10.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: current
            ? c.buttonGoldTop
            : done
                ? c.bgPrimary
                : Colors.transparent,
        border: current
            ? Border.all(color: c.buttonGoldLip, width: 2)
            : Border.all(
                color: done ? c.bgPrimary : c.borderStrong, width: 1.5),
      ),
    );
  }
}
