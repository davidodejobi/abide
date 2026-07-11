import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/database/database_provider.dart';
import 'package:openbaptisthymnal/core/theme/app_colors.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';

import '../../domain/date_key.dart';
import '../../domain/reading_plan.dart';
import '../../providers/daily_providers.dart';

Future<void> showPlanPickerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _PlanPickerSheet(),
  );
}

class _PlanPickerSheet extends ConsumerWidget {
  const _PlanPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(availablePlansProvider);
    final active = ref.watch(activePlanSubscriptionProvider).valueOrNull;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reading plans',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            plans.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator.adaptive()),
              ),
              error: (e, _) => const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "Plans couldn't be loaded.",
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              data: (list) => Column(
                children: [
                  for (final plan in list)
                    _PlanTile(
                      plan: plan,
                      isActive: plan.id == active?.planId,
                      onTap: () => _start(context, ref, plan),
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

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.isActive,
    required this.onTap,
  });

  final ReadingPlan plan;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : AppColors.secondary100,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.title,
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan.description,
                        style: AppTextStyles.bodySmall.copyWith(
                          color:
                              colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.check_circle, color: AppColors.secondary),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
