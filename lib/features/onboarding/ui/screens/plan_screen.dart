import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/features/daily/domain/plan_schedule.dart';
import 'package:openbaptisthymnal/features/daily/domain/plan_summary.dart';
import 'package:openbaptisthymnal/features/daily/providers/daily_providers.dart';
import 'package:openbaptisthymnal/features/daily/ui/widgets/plan_option_tile.dart';

import '../../domain/onboarding_defaults.dart';
import '../../providers/onboarding_provider.dart';
import '../onboarding_strings.dart';
import '../widgets/onboarding_frame.dart';

/// Step 2: pick a reading plan, with the goal and the finish line if you start
/// today.
class PlanScreen extends ConsumerWidget {
  const PlanScreen({
    super.key,
    required this.step,
    required this.total,
    required this.onNext,
    required this.onBack,
  });

  final int step;
  final int total;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lum;
    final planId = ref.watch(onboardingProvider.select((s) => s.planId));
    final plans = ref.watch(availablePlansProvider);

    return OnboardingFrame(
      step: step,
      totalSteps: total,
      onBack: onBack,
      primaryLabel: OnboardingStrings.cont,
      onPrimary: plans.hasValue ? onNext : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(OnboardingStrings.planTitle,
                style: LumText.title1.copyWith(color: c.textPrimary)),
          ),
          const SizedBox(height: LumSpace.lg),
          plans.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(LumSpace.xl),
              child: Center(child: CircularProgressIndicator.adaptive()),
            ),
            error: (e, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(OnboardingStrings.planLoadError,
                    style: LumText.body.copyWith(color: c.textSecondary)),
                TextButton(
                  onPressed: () => ref.invalidate(availablePlansProvider),
                  child: const Text(OnboardingStrings.retry),
                ),
              ],
            ),
            data: (list) {
              final today = ref.watch(planTodayProvider);
              final chosen = list.firstWhere((p) => p.id == planId,
                  orElse: () => onboardingDefaultPlan(list, today));
              return Column(
                children: [
                  for (final plan in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: LumSpace.sm),
                      child: PlanTile(
                        plan: plan,
                        selected: plan.id == chosen.id,
                        onTap: () {
                          if (!PlanSchedule(plan).isLocked(today)) {
                            ref
                                .read(onboardingProvider.notifier)
                                .setPlan(plan.id);
                          }
                        },
                      ),
                    ),
                  const SizedBox(height: LumSpace.xs),
                  _GoalCard(
                    pace: PlanOptionTile.pace(chosen),
                    finish: OnboardingStrings.shortDate(
                        planFinishDate(today, chosen.dayCount)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.pace, required this.finish});

  final String pace;
  final String finish;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Semantics(
      container: true,
      label: '${OnboardingStrings.yourGoalCaps}, $pace. '
          '${OnboardingStrings.finishLineCaps}, $finish',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(LumSpace.lg),
        decoration: BoxDecoration(
          color: c.bgSurfaceSunken,
          borderRadius: BorderRadius.circular(LumRadius.lg),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: c.buttonGoldTop),
              child:
                  Icon(Icons.flag_rounded, size: 20, color: c.buttonOnGold),
            ),
            const SizedBox(width: LumSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(OnboardingStrings.yourGoalCaps,
                      style: LumText.roadLabelCaps11
                          .copyWith(color: c.textSecondary)),
                  Text(pace,
                      style: LumText.subheadlineEmphasized
                          .copyWith(color: c.textPrimary)),
                ],
              ),
            ),
            const SizedBox(width: LumSpace.md),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(OnboardingStrings.finishLineCaps,
                      textAlign: TextAlign.end,
                      style: LumText.roadLabelCaps11
                          .copyWith(color: c.textSecondary)),
                  Text(finish,
                      textAlign: TextAlign.end,
                      style: LumText.headline.copyWith(color: c.textPrimary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
