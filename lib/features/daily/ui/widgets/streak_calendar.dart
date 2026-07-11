import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/app_colors.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';

import '../../domain/date_key.dart';

/// A contribution-graph of reading days: one square per day, weeks as columns.
///
/// Chosen over a month grid because the streak is about *runs*, and a run is
/// something you see at a glance here -- a solid column, a gap, a solid column.
/// A month view makes you count.
class StreakCalendar extends StatelessWidget {
  const StreakCalendar({
    super.key,
    required this.completedDayKeys,
    required this.today,
    this.weeks = 26,
  });

  final Set<String> completedDayKeys;
  final DateTime today;

  /// Roughly six months. Enough to show a long run without the squares becoming
  /// too small to read on a phone.
  final int weeks;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Columns end on the week containing today. weekday is 1..7 (Mon..Sun), so
    // this lands on the Monday of the current week and walks back.
    final endOfWeek = today.add(Duration(days: 7 - today.weekday));
    final start = DateTime(
      endOfWeek.year,
      endOfWeek.month,
      endOfWeek.day - (weeks * 7) + 1,
    );

    final columns = <Widget>[];
    var cursor = start;

    for (var w = 0; w < weeks; w++) {
      final cells = <Widget>[];
      for (var d = 0; d < 7; d++) {
        final key = dayKey(cursor);
        final isFuture = cursor.isAfter(today);
        cells.add(
          _Cell(
            done: completedDayKeys.contains(key),
            isToday: key == dayKey(today),
            isFuture: isFuture,
          ),
        );
        cursor = nextDay(cursor);
      }
      columns.add(
        Padding(
          padding: const EdgeInsets.only(right: 3),
          child: Column(children: cells),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true, // open at today, not six months ago
          child: Row(children: columns),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'Less',
              style: AppTextStyles.bodySmall.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 6),
            const _Cell(done: false, isToday: false, isFuture: false),
            const _Cell(done: true, isToday: false, isFuture: false),
            const SizedBox(width: 6),
            Text(
              'Read',
              style: AppTextStyles.bodySmall.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.done,
    required this.isToday,
    required this.isFuture,
  });

  final bool done;
  final bool isToday;
  final bool isFuture;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.only(bottom: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: done
            ? AppColors.secondary
            : colorScheme.onSurface.withValues(alpha: isFuture ? 0.03 : 0.08),
        // Today is outlined rather than filled when unread: a quiet "this one is
        // still open", not a reprimand.
        border: isToday && !done
            ? Border.all(color: AppColors.secondary, width: 1.5)
            : null,
      ),
    );
  }
}
