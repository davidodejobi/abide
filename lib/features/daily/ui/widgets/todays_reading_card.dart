import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
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
              // Today's streak day, shown as a status rather than baked into the
              // Mark button. It answers "did I turn up today?" without ever
              // standing between the reader and the next day of the plan.
              if (isTodayDone) ...[
                Icon(Icons.check_circle, size: 16, color: colorScheme.secondary),
                const SizedBox(width: 4),
                Text(
                  'Read today',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
              ],
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

            // The progress line opens the whole plan. Without a way in, the plan
            // is a keyhole: you see today and nothing else -- you cannot go back
            // to a passage you liked, re-read a day you rushed, or show anyone
            // what you have been reading.
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => context.router.push(
                PlanDaysRoute(planId: reading.plan.id),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Day ${day.dayIndex} of ${reading.plan.dayCount}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'All days',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: colorScheme.secondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: reading.progress,
                        minHeight: 6,
                        backgroundColor:
                            colorScheme.onSurface.withValues(alpha: 0.08),
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.secondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Short labels, deliberately. "Continue reading" wrapped onto two
            // lines inside a half-width button and looked broken; the card
            // already says what is being continued, so the verb is enough.
            //
            // "Mark read" stays enabled even once today's streak day is earned,
            // and that is the whole point. The card always shows the OLDEST day
            // you have not read, so someone three days behind marks three days
            // in one sitting and is caught up. Disabling this button after the
            // first mark -- which it used to do, by asking "is today done?"
            // instead of "is this day done?" -- meant you could never catch up
            // at all: one plan day per calendar day, forever, no matter how much
            // you actually read.
            //
            // Marking three plan days still earns exactly ONE day of streak: the
            // reading_days row is keyed on the date, so the second and third
            // marks are no-ops. You can catch up on the plan. You cannot catch
            // up on turning up.
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _open(context, ref),
                    child: const Text('Continue'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _markRead(ref),
                    child: const Text('Mark read'),
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

  Future<void> _markRead(WidgetRef ref) {
    final now = DateTime.now();

    // One transaction. These were two separate awaits, and a failure between
    // them left the user credited with a streak day for a plan day that never
    // advanced -- the card still offering the passage it had just said they read.
    //
    // Still two ROWS in two tables, deliberately: the calendar day feeds the
    // streak, the plan day advances the plan, and reading_days is keyed on the
    // date. Three marks in one evening is three days of plan and one of streak.
    return ref.read(readingPlansDaoProvider).markReadingComplete(
          dateKey: dayKey(now),
          source: 'plan',
          planId: reading.plan.id,
          dayIndex: reading.day!.dayIndex,
          completedAt: now,
        );
  }
}
