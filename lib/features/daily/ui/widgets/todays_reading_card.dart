import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/database/database_provider.dart';
import 'package:openbaptisthymnal/core/theme/app_colors.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/features/bible/ui/open_bible_link.dart';

import '../../domain/date_key.dart';
import '../../domain/passage_label.dart';
import '../../domain/plan_progress.dart';
import '../../providers/daily_providers.dart';

/// Today's reading, with the two actions that make the loop turn: open it, and
/// say you read it.
class TodaysReadingCard extends ConsumerWidget {
  const TodaysReadingCard({
    super.key,
    required this.reading,
    required this.onChangePlan,
  });

  final TodaysReading reading;
  final VoidCallback onChangePlan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bookNames = ref.watch(planBookNamesProvider).valueOrNull ?? const {};
    final isTodayDone = ref.watch(isTodayCompleteProvider);

    final day = reading.day;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : AppColors.secondary100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  reading.plan.title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
              TextButton(
                onPressed: onChangePlan,
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.secondary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Change'),
              ),
            ],
          ),
          const SizedBox(height: 4),

          if (day == null) ...[
            // Finished. Saying "choose a plan" to someone who just read the
            // Bible in a year would be a small insult.
            Text(
              'Plan complete',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You read every day of it. Start another when you are ready.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ] else ...[
            Text(
              formatPassages(day.passages, bookNames),
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Day ${day.dayIndex} of ${reading.plan.dayCount}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: reading.progress,
                minHeight: 6,
                backgroundColor: colorScheme.onSurface.withValues(alpha: 0.08),
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.secondary),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _open(context, ref),
                    child: const Text('Continue reading'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: isTodayDone ? null : () => _markRead(ref),
                    child: Text(isTodayDone ? 'Read today' : 'Mark as read'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) {
    // openingRefFor, NOT the passage's full range. BibleLinkResolver keeps a
    // range's end VERSE but drops its end CHAPTER, so handing it `GEN.1.1-4.26`
    // opens Genesis 1 and flashes "verses 1-26" of that chapter -- a highlight
    // that means nothing, on most days of most plans. See plan_progress.dart.
    return openBibleLink(
      context,
      ref,
      targetKey: openingRefFor(reading.day!),
    );
  }

  Future<void> _markRead(WidgetRef ref) async {
    final dao = ref.read(readingPlansDaoProvider);
    final now = DateTime.now();

    // Two writes, deliberately. The calendar day feeds the streak; the plan day
    // advances the plan. Catching up on three plan days in one sitting is one
    // day of streak and three of progress, and collapsing them into one row
    // would let someone binge a 30-day streak in an afternoon.
    await dao.markDayComplete(
      dateKey: dayKey(now),
      source: 'plan',
      completedAt: now,
    );
    await dao.markPlanDayComplete(
      planId: reading.plan.id,
      dayIndex: reading.day!.dayIndex,
      completedAt: now,
    );
  }
}
