import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/widgets/lum_page_background.dart';

import '../domain/date_key.dart';
import '../providers/daily_providers.dart';
import 'daily_strings.dart';
import 'widgets/lamp_icon.dart';
import 'widgets/streak_calendar.dart';

/// Streak detail (Figma M1-10): the run as a big number, then the month as
/// what it is, a record of days. A missed day is a plain number, never a loss.
@RoutePage()
class StreakPage extends ConsumerWidget {
  const StreakPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lum;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final streak = ref.watch(streakProvider);
    final days = ref.watch(completedDayKeysProvider).valueOrNull ?? const {};
    final reading = ref.watch(todaysReadingProvider).valueOrNull;
    final today = dateFromKey(todayKey())!;
    final grace = graceDayKeys(days, streak, today);
    final tone = dark ? 'dark' : 'light';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: LumPageBackground()),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 340,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [c.sceneSkyTop, c.sceneSkyTop.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  LumSize.screenGutter + 4, 8, LumSize.screenGutter + 4, 40),
              children: [
                SizedBox(
                  height: LumSize.touchTarget,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Semantics(
                          button: true,
                          label: DailyStrings.back,
                          excludeSemantics: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => context.router.maybePop(),
                            child: Container(
                              width: LumSize.touchTarget,
                              height: LumSize.touchTarget,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: c.chip,
                                border: Border.all(color: c.borderSubtle),
                              ),
                              child: Icon(Icons.chevron_left_rounded,
                                  size: 28, color: c.textPrimary),
                            ),
                          ),
                        ),
                      ),
                      Semantics(
                        header: true,
                        child: Text(DailyStrings.streakTitle,
                            style: LumText.headline
                                .copyWith(color: c.textPrimary)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: LumSpace.lg),
                Text(DailyStrings.daysWithTheWord,
                    style: LumText.roadLabelCaps11
                        .copyWith(color: c.textSecondary)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Semantics(
                      label: DailyStrings.streakChipSemantics(streak.current),
                      excludeSemantics: true,
                      child: Text('${streak.current}',
                          textScaler: TextScaler.noScaling,
                          style: LumText.roadDisplayHero120
                              .copyWith(color: c.textPrimary)),
                    ),
                    if (reading != null && !reading.isFinished)
                      Expanded(
                        child: _Vignette(
                          tone: tone,
                          day: reading.day!.dayIndex,
                          total: reading.plan.dayCount,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: LumSpace.md),
                Row(
                  children: [
                    const LampIcon(size: 22),
                    const SizedBox(width: LumSpace.sm),
                    Text(DailyStrings.longest(streak.longest),
                        style: LumText.subheadlineEmphasized
                            .copyWith(color: c.textPrimary)),
                  ],
                ),
                const SizedBox(height: LumSpace.sm),
                // The only number that never goes down: a year of reading is
                // not undone by one bad week.
                Text(DailyStrings.totalDays(streak.totalDays),
                    style: LumText.subheadline.copyWith(color: c.textSecondary)),
                const SizedBox(height: LumSpace.xl),
                StreakMonthGrid(
                  completed: days,
                  grace: grace,
                  today: today,
                  streakDays: streak.current,
                ),
                const SizedBox(height: LumSpace.xl),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.eco_rounded, size: 32, color: c.iconSuccess),
                    const SizedBox(width: LumSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DailyStrings.graceTitle,
                              style: LumText.subheadlineEmphasized
                                  .copyWith(color: c.textPrimary)),
                          const SizedBox(height: 2),
                          Text(DailyStrings.graceBody,
                              style: LumText.footnote
                                  .copyWith(color: c.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A done stop with the traveller beside the current stop (decorative).
class _Vignette extends StatelessWidget {
  const _Vignette({required this.tone, required this.day, required this.total});

  final String tone;
  final int day;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return ExcludeSemantics(
      child: SizedBox(
        height: 150,
        child: LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Done stop and the traveller standing on it.
              Positioned(
                left: w * 0.02,
                bottom: 0,
                width: 120,
                height: 90,
                child: Image.asset('assets/images/road/stop_done_$tone.png',
                    fit: BoxFit.fill),
              ),
              Positioned(
                left: w * 0.02 + 30,
                bottom: 30,
                width: 56,
                height: 77,
                child: Image.asset(
                    'assets/images/road/traveller_walking_$tone.png',
                    fit: BoxFit.contain),
              ),
              // Current stop, glowing, up and to the right.
              Positioned(
                right: -8,
                top: 8,
                width: 120,
                height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset('assets/images/road/stop_current_$tone.png',
                        fit: BoxFit.fill),
                    Text('$day',
                        textScaler: TextScaler.noScaling,
                        style: LumText.roadDisplayStat28.copyWith(
                            fontSize: 20, color: c.sceneStopOnCurrent)),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
