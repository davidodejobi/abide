import 'dart:ui' show ViewPadding;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/storage/database/database_provider.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/utils/time_greeting.dart';
import 'package:openbaptisthymnal/core/widgets/lum_button.dart';
import 'package:openbaptisthymnal/features/bible/ui/open_bible_link.dart';
import 'package:openbaptisthymnal/features/onboarding/providers/onboarding_provider.dart';

import '../domain/date_key.dart';
import '../domain/passage_label.dart';
import '../domain/plan_progress.dart';
import '../domain/reading_plan.dart';
import '../providers/daily_providers.dart';
import 'daily_strings.dart';
import 'widgets/lamp_icon.dart';
import 'widgets/plan_picker_sheet.dart';
import 'widgets/road_scene.dart';
import 'widgets/streak_chip.dart';

/// The Today tab: the road scene, today's reading and the one button that
/// starts it. After "Mark as read" the same screen turns to evening and says
/// what tomorrow holds (Figma M1-01, M1-08, M1-12).
///
/// Reads the existing daily providers only; nothing about plans or streaks is
/// computed here beyond display arithmetic.
@RoutePage()
class TodayTabScreen extends ConsumerStatefulWidget {
  const TodayTabScreen({super.key});

  @override
  ConsumerState<TodayTabScreen> createState() => _TodayTabScreenState();
}

class _TodayTabScreenState extends ConsumerState<TodayTabScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  /// "Read ahead" after the day is done: show the next day's reading again so
  /// a reader catching up can keep going. Plan days are progress-driven, so
  /// marking more than one a day is allowed (see the old card's notes).
  bool _readAhead = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = context.lum;
    final name = ref.watch(userNameProvider);
    final streak = ref.watch(streakProvider);
    final reading = ref.watch(todaysReadingProvider);
    final todayDone = ref.watch(isTodayCompleteProvider);
    final bookNames = ref.watch(planBookNamesProvider).valueOrNull ?? const {};

    final data = reading.valueOrNull;
    final hasPlan = data != null;
    final done = hasPlan && todayDone && data.completedDays > 0 && !_readAhead;
    final mood = done ? RoadMood.evening : RoadMood.day;
    final greeting = TimeGreeting.now().greeting;
    final now = DateTime.now();

    final title = done ? DailyStrings.restWell : greeting;
    final headText = name == null ? title : '$title, $name';
    final overSky = done ? c.textOnEveningSky : c.textPrimary;
    final overSkySecondary = done ? c.textOnEveningSky : c.textSecondary;

    // The tab sits inside a SafeArea; the scene bleeds up under the status bar.
    final view = View.of(context);
    final ViewPadding vp = view.padding;
    final inset = vp.top / view.devicePixelRatio;

    final width = MediaQuery.sizeOf(context).width;
    final k = width / RoadScene.designWidth;
    final panelTop = (done ? 404 : 392) * k - inset;

    final int? currentDay;
    final int total;
    if (!hasPlan) {
      currentDay = 1;
      total = 9999;
    } else if (data.isFinished) {
      currentDay = null;
      total = data.plan.dayCount;
    } else {
      currentDay = data.day!.dayIndex;
      total = data.plan.dayCount;
    }

    return LayoutBuilder(
      builder: (context, box) {
        return SingleChildScrollView(
          clipBehavior: Clip.none,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -inset,
                  left: 0,
                  child: RoadScene(
                    width: width,
                    mood: mood,
                    currentDay: currentDay,
                    totalDays: total,
                    showTomorrowTag: done,
                  ),
                ),
                Positioned(
                  top: 24,
                  left: LumSize.screenGutter + 4,
                  right: LumSize.screenGutter + 4,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              done
                                  ? DailyStrings.eveningCaps(now)
                                  : DailyStrings.dateCaps(now),
                              style: LumText.roadLabelCaps11
                                  .copyWith(color: overSkySecondary),
                            ),
                            const SizedBox(height: 10),
                            Semantics(
                              header: true,
                              child: Text(
                                headText,
                                style: LumText.title1
                                    .copyWith(color: overSky),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (streak.isActive)
                        Padding(
                          padding: const EdgeInsets.only(left: LumSpace.md),
                          child: StreakChip(
                            days: streak.current,
                            onTap: () =>
                                context.router.push(const StreakRoute()),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: panelTop),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (box.maxHeight - panelTop).clamp(0, 4000),
                    ),
                    child: _Panel(
                      child: reading.when(
                        loading: () => const SizedBox(height: 160),
                        error: (e, _) => Text(
                          DailyStrings.loadError,
                          style: LumText.body.copyWith(color: c.textSecondary),
                        ),
                        data: (d) => d == null
                            ? _NoPlan(onChoose: _choosePlan)
                            : d.isFinished
                                ? _Finished(
                                    reading: d,
                                    bookNames: bookNames,
                                    onChoose: _choosePlan,
                                  )
                                : done
                                    ? _DayDone(
                                        reading: d,
                                        bookNames: bookNames,
                                        streakDays: streak.current,
                                        onReadAhead: () =>
                                            setState(() => _readAhead = true),
                                      )
                                    : _Reading(
                                        reading: d,
                                        bookNames: bookNames,
                                        onChange: _choosePlan,
                                        onMarkRead: () => _markRead(d),
                                      ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _choosePlan() => showPlanPickerSheet(context);

  Future<void> _markRead(TodaysReading d) {
    final now = DateTime.now();
    // One transaction: the calendar day feeds the streak, the plan day advances
    // the plan. Three marks in one evening is three plan days and one streak day.
    setState(() => _readAhead = false);
    return ref.read(readingPlansDaoProvider).markReadingComplete(
          dateKey: dayKey(now),
          source: 'plan',
          planId: d.plan.id,
          dayIndex: d.day!.dayIndex,
          completedAt: now,
        );
  }
}

/// The rounded panel the reading sits on, over the lower scene.
class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.scenePanel,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: c.sceneShadow,
            blurRadius: 28,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      // 120 at the bottom clears the floating tab bar.
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      child: child,
    );
  }
}

int _chapters(PlanDay day) => day.passages
    .fold<int>(0, (n, p) => n + (p.end.chapter - p.start.chapter + 1));

/// Plan active, today not done (M1-01).
class _Reading extends ConsumerWidget {
  const _Reading({
    required this.reading,
    required this.bookNames,
    required this.onChange,
    required this.onMarkRead,
  });

  final TodaysReading reading;
  final Map<String, String> bookNames;
  final VoidCallback onChange;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lum;
    final day = reading.day!;
    final passage = formatPassages(day.passages, bookNames);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(reading.plan.title.toUpperCase(),
            style: LumText.roadLabelCaps11.copyWith(color: c.textSecondary)),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Semantics(
              label: DailyStrings.dayN(day.dayIndex),
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DailyStrings.dayLabel,
                      style: LumText.roadLabelCaps11
                          .copyWith(color: c.textSecondary)),
                  Text(
                    '${day.dayIndex}',
                    textScaler: TextScaler.noScaling,
                    style: LumText.roadDisplayHero120
                        .copyWith(color: c.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DailyStrings.todaysReading.toUpperCase(),
                        style: LumText.roadLabelCaps11
                            .copyWith(color: c.textSecondary)),
                    const SizedBox(height: 4),
                    Text(passage,
                        style: LumText.roadTitleLarge34
                            .copyWith(color: c.textPrimary)),
                    const SizedBox(height: 4),
                    Text(DailyStrings.chapters(_chapters(day)),
                        style: LumText.footnote
                            .copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LumButton(
          label: DailyStrings.startReading,
          icon: const Icon(Icons.menu_book_outlined),
          onPressed: () => openBibleLink(
            context,
            ref,
            targetKey: openingRefFor(day),
          ),
        ),
        const SizedBox(height: 12),
        // "Mark as read" lives here until the reader (step 3) carries it; the
        // Figma Today has only Start reading.
        LumButton(
          label: DailyStrings.markRead,
          kind: LumButtonKind.secondary,
          icon: const Icon(Icons.check_rounded),
          onPressed: onMarkRead,
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _TextAction(
              label:
                  '${DailyStrings.dayOfTotal(day.dayIndex, reading.plan.dayCount)} · ${DailyStrings.allDays}',
              onTap: () => context.router
                  .push(PlanDaysRoute(planId: reading.plan.id)),
            ),
            _TextAction(label: DailyStrings.changePlan, onTap: onChange),
          ],
        ),
      ],
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LumRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: LumSize.touchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: LumSpace.xs),
            child: Align(
              widthFactor: 1,
              child: Text(label,
                  style: LumText.footnoteEmphasized
                      .copyWith(color: c.textSecondary)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Plan active, today done (M1-08).
class _DayDone extends ConsumerWidget {
  const _DayDone({
    required this.reading,
    required this.bookNames,
    required this.streakDays,
    required this.onReadAhead,
  });

  final TodaysReading reading;
  final Map<String, String> bookNames;
  final int streakDays;
  final VoidCallback onReadAhead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lum;
    final next = reading.day!.dayIndex;
    final doneIndex = next - 1;
    final doneDay = reading.plan.dayAt(doneIndex);
    final passage =
        doneDay == null ? '' : formatPassages(doneDay.passages, bookNames);
    final pct = reading.plan.dayCount == 0
        ? 0
        : (reading.completedDays * 100 / reading.plan.dayCount).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.check_rounded, size: 16, color: c.iconSuccess),
            const SizedBox(width: 4),
            Flexible(
              child: Text(DailyStrings.doneCaps(passage),
                  style: LumText.roadLabelCaps11
                      .copyWith(color: c.textOnSuccessContainer)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(DailyStrings.dayN(doneIndex),
            textScaler: TextScaler.noScaling,
            style: LumText.roadDisplayLarge76.copyWith(color: c.textPrimary)),
        const SizedBox(height: 4),
        Text(DailyStrings.tomorrowDay(next),
            style: LumText.callout.copyWith(color: c.textSecondary)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _Tile(
                streak: true,
                value: '$streakDays',
                label: DailyStrings.dayStreak,
                leading: const LampIcon(size: 22),
              ),
            ),
            const SizedBox(width: LumSpace.sm),
            Expanded(
              child: _Tile(
                value: DailyStrings.percent(pct),
                label: DailyStrings.ofThePlan,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        LumButton(
          label: DailyStrings.writeNote,
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => context.router.push(TabletEditorRoute()),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: _TextAction(label: DailyStrings.readAhead, onTap: onReadAhead),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.value,
    required this.label,
    this.leading,
    this.streak = false,
  });

  final String value;
  final String label;
  final Widget? leading;
  final bool streak;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    final fg = streak ? c.tileOnStreak : c.textPrimary;
    return Semantics(
      label: '$value $label',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.all(LumSpace.md),
        decoration: BoxDecoration(
          color: streak ? c.tileStreak : c.bgSurface,
          borderRadius: BorderRadius.circular(LumRadius.lg),
          border: streak ? null : Border.all(color: c.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 6)],
                Flexible(
                  child: Text(value,
                      maxLines: 1,
                      style: LumText.roadDisplayStat28.copyWith(color: fg)),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(label,
                style: LumText.footnote
                    .copyWith(color: streak ? c.tileOnStreak : c.textSecondary)),
          ],
        ),
      ),
    );
  }
}

/// No plan picked yet (M1-12).
class _NoPlan extends StatelessWidget {
  const _NoPlan({required this.onChoose});

  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(DailyStrings.noPlanCaps.toUpperCase(),
            style: LumText.roadLabelCaps11.copyWith(color: c.textSecondary)),
        const SizedBox(height: 8),
        Semantics(
          header: true,
          child: Text(DailyStrings.noPlanTitle,
              style: LumText.roadTitleLarge34.copyWith(color: c.textPrimary)),
        ),
        const SizedBox(height: 8),
        Text(DailyStrings.noPlanBody,
            style: LumText.callout.copyWith(color: c.textSecondary)),
        const SizedBox(height: 20),
        LumButton(
          label: DailyStrings.choosePlan,
          icon: const Icon(Icons.menu_book_outlined),
          onPressed: onChoose,
        ),
      ],
    );
  }
}

/// Plan finished: not "choose a plan", someone just read all of it.
class _Finished extends StatelessWidget {
  const _Finished({
    required this.reading,
    required this.bookNames,
    required this.onChoose,
  });

  final TodaysReading reading;
  final Map<String, String> bookNames;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(reading.plan.title.toUpperCase(),
            style: LumText.roadLabelCaps11.copyWith(color: c.textSecondary)),
        const SizedBox(height: 8),
        Semantics(
          header: true,
          child: Text(DailyStrings.planCompleteTitle,
              style: LumText.roadTitleLarge34.copyWith(color: c.textPrimary)),
        ),
        const SizedBox(height: 8),
        Text(DailyStrings.planCompleteBody,
            style: LumText.callout.copyWith(color: c.textSecondary)),
        const SizedBox(height: 20),
        LumButton(
          label: DailyStrings.chooseAnotherPlan,
          icon: const Icon(Icons.menu_book_outlined),
          onPressed: onChoose,
        ),
      ],
    );
  }
}
