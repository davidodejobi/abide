import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/app_colors.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';

import '../../domain/streak.dart';

/// The streak, stated plainly.
///
/// Deliberately not a guilt machine. A broken streak reads as an invitation
/// back, not a failure notice, and a rest day is named as a rest day rather
/// than hidden -- the audience is people building a devotional habit, and
/// pretending their week was perfect when it was not is exactly the kind of
/// small dishonesty that makes someone stop trusting the number.
class StreakHeader extends StatelessWidget {
  const StreakHeader({super.key, required this.streak});

  final StreakResult streak;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : AppColors.secondary100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  streak.isActive ? _dayCount(streak.current) : 'No streak yet',
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitle(streak),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _Flame(active: streak.isActive, done: streak.completedToday),
        ],
      ),
    );
  }

  String _dayCount(int days) => days == 1 ? '1 day' : '$days days';

  String _subtitle(StreakResult streak) {
    if (!streak.isActive) return 'Read today to begin one.';
    if (!streak.completedToday) return "Today isn't done yet.";
    if (streak.graceDaysUsed > 0) {
      final rest = streak.graceDaysUsed == 1
          ? 'a rest day'
          : '${streak.graceDaysUsed} rest days';
      return 'Kept going, with $rest.';
    }
    return 'Every day so far.';
  }
}

class _Flame extends StatelessWidget {
  const _Flame({required this.active, required this.done});

  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Gold once today is actually done. An always-lit badge would say the same
    // thing whether or not the user turned up, which is the fastest way to make
    // it mean nothing.
    final lit = active && done;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: lit
            ? AppColors.secondary.withValues(alpha: 0.18)
            : colorScheme.onSurface.withValues(alpha: 0.06),
      ),
      child: Icon(
        lit ? Icons.local_fire_department : Icons.local_fire_department_outlined,
        size: 22,
        color: lit
            ? AppColors.secondary
            : colorScheme.onSurface.withValues(alpha: 0.35),
      ),
    );
  }
}
