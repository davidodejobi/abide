import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/database/database_provider.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';

import '../../domain/date_key.dart';
import '../../domain/reading_plan.dart';
import '../../providers/daily_providers.dart';
import '../daily_strings.dart';
import 'plan_option_tile.dart';

Future<void> showPlanPickerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: context.lum.bgPage,
    builder: (_) => const _PlanPickerSheet(),
  );
}

class _PlanPickerSheet extends ConsumerWidget {
  const _PlanPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lum;
    final plans = ref.watch(availablePlansProvider);
    final active = ref.watch(activePlanSubscriptionProvider).valueOrNull;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            LumSize.screenGutter, 0, LumSize.screenGutter, LumSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(DailyStrings.planSheetTitle,
                  style: LumText.title2.copyWith(color: c.textPrimary)),
            ),
            const SizedBox(height: LumSpace.xs),
            Text(DailyStrings.planSheetBody,
                style: LumText.subheadline.copyWith(color: c.textSecondary)),
            const SizedBox(height: LumSpace.lg),
            plans.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(LumSpace.xl),
                child: Center(child: CircularProgressIndicator.adaptive()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(LumSpace.xl),
                child: Text(DailyStrings.plansLoadError,
                    style: LumText.body.copyWith(color: c.textSecondary)),
              ),
              data: (list) => Column(
                children: [
                  for (final plan in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: LumSpace.sm),
                      child: _PlanRow(
                        plan: plan,
                        isActive: plan.id == active?.planId,
                        onTap: () => _start(context, ref, plan),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _start(
    BuildContext context,
    WidgetRef ref,
    ReadingPlan plan,
  ) async {
    // startPlan is idempotent and keeps existing progress, so re-picking the
    // plan you are already on resumes rather than restarting. Wiping progress is
    // a separate, deliberate action -- never a side effect of a tap in a list.
    await ref.read(readingPlansDaoProvider).startPlan(
          planId: plan.id,
          startDateKey: todayKey(),
        );
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _PlanRow extends ConsumerWidget {
  const _PlanRow({
    required this.plan,
    required this.isActive,
    required this.onTap,
  });

  final ReadingPlan plan;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Progress is kept per plan and is never cleared by switching, so a plan you
    // put down months ago still knows where you were. Saying so here is the
    // point: without it, "Change" looks like it might throw away your place, and
    // nobody risks that to go and look.
    final done =
        ref.watch(planProgressProvider(plan.id)).valueOrNull ?? const <int>{};
    return PlanOptionTile(
      plan: plan,
      selected: isActive,
      onTap: onTap,
      footnote: done.isEmpty
          ? null
          : isActive
              ? DailyStrings.daysRead(done.length, plan.dayCount)
              : DailyStrings.resumesAt(done.length, plan.dayCount),
    );
  }
}
