import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/theme/app_colors.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';

import '../domain/date_key.dart';
import '../providers/daily_providers.dart';
import 'widgets/streak_calendar.dart';

/// The streak, shown as what it actually is: a record of days.
///
/// The number on the Today card is a summary, and a summary invites the question
/// "of what?". This answers it -- every day marked, laid out on a calendar, so
/// the streak is something the user can check rather than something the app
/// merely asserts.
@RoutePage()
class StreakPage extends ConsumerWidget {
  const StreakPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);
    final days = ref.watch(completedDayKeysProvider).valueOrNull ?? const {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your reading'),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: _Stat(
                  value: '${streak.current}',
                  label: streak.current == 1 ? 'day now' : 'days now',
                  emphasised: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Stat(
                  value: '${streak.longest}',
                  label: 'best run',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Stat(
                  // The only number that never goes down. Worth the space
                  // precisely for the week someone breaks a streak: a year of
                  // reading is not undone by one bad week, and the screen should
                  // say so rather than lead with the loss.
                  value: '${streak.totalDays}',
                  label: 'days total',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text(
            'Last 6 months',
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          StreakCalendar(
            completedDayKeys: days,
            today: dateFromKey(todayKey())!,
          ),

          const SizedBox(height: 24),
          if (streak.graceDaysUsed > 0)
            Text(
              streak.graceDaysUsed == 1
                  ? 'One rest day is kept in your current run. A missed day a '
                      'week does not break it.'
                  : '${streak.graceDaysUsed} rest days are kept in your current '
                      'run. A missed day a week does not break it.',
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            )
          else
            Text(
              'A missed day a week does not break your streak. Two in a row '
              'will.',
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    this.emphasised = false,
  });

  final String value;
  final String label;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : AppColors.secondary100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: emphasised ? AppColors.secondary : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
