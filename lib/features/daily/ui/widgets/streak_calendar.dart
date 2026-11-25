import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';

import '../../domain/date_key.dart';
import '../../domain/streak.dart';
import '../daily_strings.dart';

/// The days of the current run that were forgiven by the grace rule: missed
/// days sitting between read days of the run. Derived from the same inputs the
/// streak is, so it can never disagree with it. Today is never a miss.
Set<String> graceDayKeys(
  Set<String> completed,
  StreakResult streak,
  DateTime today,
) {
  final grace = <String>{};
  if (streak.current == 0) return grace;
  var cursor = completed.contains(dayKey(today)) ? today : previousDay(today);
  var counted = 0;
  for (var i = 0; i < 800 && counted < streak.current; i++) {
    if (completed.contains(dayKey(cursor))) {
      counted++;
    } else {
      grace.add(dayKey(cursor));
    }
    cursor = previousDay(cursor);
  }
  return grace;
}

/// One month as a Monday-first grid (Figma M1-10): read = check, grace = leaf,
/// missed = a plain number, today = a gold ring. Never colour alone, never red.
class StreakMonthGrid extends StatelessWidget {
  const StreakMonthGrid({
    super.key,
    required this.completed,
    required this.grace,
    required this.today,
    required this.streakDays,
  });

  final Set<String> completed;
  final Set<String> grace;
  final DateTime today;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    final first = DateTime(today.year, today.month, 1);
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
    final lead = first.weekday - 1;
    final rows = ((lead + daysInMonth) / 7).ceil();

    Widget cell(int? day) {
      if (day == null) return const SizedBox(height: 44);
      final d = DateTime(today.year, today.month, day);
      final key = dayKey(d);
      final isToday = day == today.day;
      final read = completed.contains(key);
      final isGrace = !read && grace.contains(key);
      Widget inner;
      String sem;
      if (read) {
        inner = Icon(Icons.check_rounded, size: 20, color: c.textPrimary);
        sem = 'read';
      } else if (isGrace) {
        inner = Icon(Icons.eco_rounded, size: 22, color: c.iconSuccess);
        sem = 'grace day';
      } else {
        inner = Text('$day',
            style: LumText.subheadline.copyWith(
                color: d.isAfter(today) ? c.textDisabled : c.textSecondary));
        sem = d.isAfter(today) ? '' : 'not read';
      }
      return Semantics(
        label: '$day, ${isToday ? 'today, ' : ''}$sem',
        excludeSemantics: true,
        child: Center(
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: read ? c.bgElevated : null,
              border: isToday
                  ? Border.all(color: c.sceneStopCurrentTop, width: 2.5)
                  : (read ? Border.all(color: c.borderSubtle) : null),
            ),
            child: isToday && !read
                ? Text('$day',
                    style: LumText.subheadlineEmphasized
                        .copyWith(color: c.textPrimary))
                : inner,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(LumSpace.lg),
      decoration: BoxDecoration(
        color: c.scenePanel,
        borderRadius: BorderRadius.circular(LumRadius.xl),
        border: Border.all(color: c.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(DailyStrings.monthYear(today),
                    style: LumText.headline.copyWith(color: c.textPrimary)),
              ),
              Text(DailyStrings.inARow(streakDays),
                  style: LumText.footnoteEmphasized
                      .copyWith(color: c.textSecondary)),
            ],
          ),
          const SizedBox(height: LumSpace.md),
          Row(
            children: [
              for (final l in DailyStrings.weekdayInitials)
                Expanded(
                  child: ExcludeSemantics(
                    child: Center(
                      child: Text(l,
                          style: LumText.footnoteEmphasized
                              .copyWith(color: c.textSecondary)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: LumSpace.sm),
          for (var r = 0; r < rows; r++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  for (var col = 0; col < 7; col++)
                    Expanded(
                      child: () {
                        final n = r * 7 + col - lead + 1;
                        return cell(n >= 1 && n <= daysInMonth ? n : null);
                      }(),
                    ),
                ],
              ),
            ),
          const SizedBox(height: LumSpace.sm),
          Wrap(
            spacing: LumSpace.lg,
            runSpacing: LumSpace.sm,
            children: [
              _Legend(
                swatch: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: c.bgElevated,
                      border: Border.all(color: c.borderSubtle)),
                ),
                label: DailyStrings.legendRead,
              ),
              _Legend(
                swatch: Icon(Icons.eco_rounded, size: 18, color: c.iconSuccess),
                label: DailyStrings.legendGrace,
              ),
              _Legend(
                swatch: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: c.sceneStopCurrentTop, width: 2)),
                ),
                label: DailyStrings.legendToday,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.swatch, required this.label});

  final Widget swatch;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        swatch,
        const SizedBox(width: 6),
        Text(label,
            style: LumText.footnote.copyWith(color: c.textSecondary)),
      ],
    );
  }
}
