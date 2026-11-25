import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';

import '../../domain/plan_summary.dart';
import '../../domain/reading_plan.dart';

/// One plan as a row: title and pace on the left, the day count big on the
/// right. Selected is the ink card with a gold number (Figma 1.04 / M10).
/// Shared by the onboarding plan step and the plan picker sheet.
class PlanOptionTile extends StatelessWidget {
  const PlanOptionTile({
    super.key,
    required this.plan,
    required this.selected,
    required this.onTap,
    this.footnote,
  });

  final ReadingPlan plan;
  final bool selected;
  final VoidCallback onTap;

  /// Extra line under the pace, e.g. "Resumes at 4 of 90 days".
  final String? footnote;

  static String pace(ReadingPlan plan) {
    final n = averageChaptersPerDay(plan);
    return n == 1 ? 'About 1 chapter a day' : 'About $n chapters a day';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    final fg = selected ? c.textOnPrimary : c.textPrimary;
    final fgSoft =
        selected ? c.textOnPrimary.withValues(alpha: 0.75) : c.textSecondary;
    final number = selected ? c.buttonGoldTop : c.textPrimary;
    final label = '${plan.title}, ${plan.dayCount} days, ${pace(plan)}'
        '${footnote == null ? '' : ', $footnote'}';
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: LumMotion.fast,
          constraints: const BoxConstraints(minHeight: LumSize.rowMin + 16),
          padding: const EdgeInsets.all(LumSpace.lg),
          decoration: BoxDecoration(
            color: selected ? c.bgPrimary : c.bgSurface,
            borderRadius: BorderRadius.circular(LumRadius.lg),
            border: selected ? null : Border.all(color: c.borderSubtle),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selected) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_rounded, size: 16, color: number),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text('SELECTED',
                                style: LumText.roadLabelCaps11
                                    .copyWith(color: number)),
                          ),
                        ],
                      ),
                      const SizedBox(height: LumSpace.xs),
                    ],
                    Text(plan.title,
                        style: LumText.headline.copyWith(color: fg)),
                    const SizedBox(height: LumSpace.xs),
                    Text(pace(plan),
                        style: LumText.footnote.copyWith(color: fgSoft)),
                    if (footnote != null) ...[
                      const SizedBox(height: LumSpace.xs),
                      Text(footnote!,
                          style: LumText.footnoteEmphasized.copyWith(
                              color: selected ? number : c.textBrand)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: LumSpace.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${plan.dayCount}',
                      textScaler: MediaQuery.textScalerOf(context)
                          .clamp(maxScaleFactor: 1.3),
                      style: LumText.roadDisplayStat28.copyWith(
                          color: number, fontSize: selected ? 44 : 30)),
                  if (selected)
                    Text('DAYS',
                        style:
                            LumText.roadLabelCaps11.copyWith(color: fgSoft)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
