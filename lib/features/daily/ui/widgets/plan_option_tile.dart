import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';

import '../../domain/plan_schedule.dart';
import '../../domain/plan_summary.dart';
import '../../domain/reading_plan.dart';
import '../../providers/daily_providers.dart';
import 'package:openbaptisthymnal/features/settings/ui/you_strings.dart';
import '../daily_strings.dart';

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
    this.lockedNote,
    this.reminderOn = false,
    this.onReminderChanged,
  });

  final ReadingPlan plan;
  final bool selected;
  final VoidCallback onTap;

  /// Extra line under the pace, e.g. "Resumes at 4 of 90 days".
  final String? footnote;

  /// Set when the plan is not open yet ("Starts 1 January · 37 days to go"):
  /// the tile dims, shows a lock and the remind toggle, and ignores taps.
  final String? lockedNote;
  final bool reminderOn;
  final ValueChanged<bool>? onReminderChanged;

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
    final locked = lockedNote != null;
    final note = lockedNote ?? footnote;
    final label = '${plan.title}, ${plan.dayCount} days, ${pace(plan)}'
        '${note == null ? '' : ', $note'}';
    return Semantics(
      button: !locked,
      selected: selected && !locked,
      label: label,
      excludeSemantics: !locked,
      onTap: locked ? null : onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: locked ? null : onTap,
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
                    if (locked) ...[
                      const SizedBox(height: LumSpace.xs),
                      Row(children: [
                        Icon(Icons.lock_outline_rounded,
                            size: 16, color: c.textBrand),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(lockedNote!,
                              style: LumText.footnoteEmphasized
                                  .copyWith(color: c.textBrand)),
                        ),
                      ]),
                      if (onReminderChanged != null)
                        Row(children: [
                          Expanded(
                            child: Text(DailyStrings.remindMe,
                                style: LumText.subheadline
                                    .copyWith(color: c.textPrimary)),
                          ),
                          Switch.adaptive(
                              value: reminderOn, onChanged: onReminderChanged),
                        ]),
                      Text(DailyStrings.warmUp,
                          style: LumText.footnote.copyWith(color: fgSoft)),
                    ] else if (footnote != null) ...[
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
                        style: LumText.roadLabelCaps11.copyWith(color: fgSoft)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A plan tile that knows about fixed-start plans: while the plan is locked it
/// shows the countdown and the "Remind me" toggle, and taps do nothing.
class PlanTile extends ConsumerWidget {
  const PlanTile({
    super.key,
    required this.plan,
    required this.selected,
    required this.onTap,
    this.footnote,
  });

  final ReadingPlan plan;
  final bool selected;
  final VoidCallback onTap;
  final String? footnote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = PlanSchedule(plan);
    final today = ref.watch(planTodayProvider);
    final sub = ref.watch(planSubscriptionProvider(plan.id)).valueOrNull;
    // Someone already on the plan before it was anchored keeps it open.
    final legacy = sub != null && schedule.isLegacy(sub.startDateKey);
    final locked = schedule.isLocked(today) && !legacy;
    final remind = ref.watch(planRemindersProvider).contains(plan.id);
    return PlanOptionTile(
      plan: plan,
      selected: selected && !locked,
      onTap: onTap,
      footnote: footnote,
      lockedNote: locked
          ? DailyStrings.startsOnLocked(
              schedule.startLabel, schedule.daysToGo(today))
          : null,
      reminderOn: remind,
      onReminderChanged: (on) async {
        final messenger = ScaffoldMessenger.maybeOf(context);
        final ok =
            await ref.read(planRemindersProvider.notifier).toggle(plan.id, on);
        if (!ok) {
          messenger?.showSnackBar(
              const SnackBar(content: Text(YouStrings.reminderDenied)));
        }
      },
    );
  }
}
