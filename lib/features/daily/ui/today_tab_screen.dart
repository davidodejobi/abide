import 'dart:math' as math;
import 'dart:ui' as ui show Image;
import 'dart:ui' show ViewPadding;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/utils/day_part_provider.dart';
import 'package:openbaptisthymnal/core/utils/time_greeting.dart';
import 'package:openbaptisthymnal/core/widgets/lum_button.dart';
import 'package:openbaptisthymnal/features/bible/ui/open_bible_link.dart';
import 'package:openbaptisthymnal/features/onboarding/providers/onboarding_provider.dart';

import '../domain/date_key.dart';
import '../domain/plan_schedule.dart';
import '../domain/passage_label.dart';
import '../domain/plan_progress.dart';
import '../domain/reading_plan.dart';
import '../domain/road_days.dart';
import '../domain/road_landmarks.dart';
import '../providers/daily_providers.dart';
import 'daily_strings.dart';
import 'widgets/lamp_icon.dart';
import 'widgets/plan_picker_sheet.dart';
import 'widgets/road_art.dart';
import 'widgets/road_scene.dart';
import 'widgets/road_sheets.dart';
import 'widgets/streak_chip.dart';

/// The Today tab: the road scene, today's reading and the one button that
/// starts it. After "Mark as read" the same screen says well done (or rest
/// well at dusk) and names what tomorrow holds (Figma M1-01, M1-08, M1-12).
///
/// Reads the existing daily providers only; nothing about plans or streaks is
/// computed here beyond display arithmetic.
@RoutePage()
class TodayTabScreen extends ConsumerStatefulWidget {
  const TodayTabScreen({super.key});

  @override
  ConsumerState<TodayTabScreen> createState() => _TodayTabScreenState();
}

const double _maxSceneWidth = 430;

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
    // Which plan day was finished today (the highest one before the next
    // unread day), or null if none, e.g. day 1 was unmarked again.
    final doneAsync =
        hasPlan ? ref.watch(planDaysDoneTodayProvider(data.progressKey)) : null;
    final next = data?.day?.dayIndex;
    final anchored = data?.isAnchored ?? false;
    // Anchored plans: done means today's calendar day is read, nothing else.
    final doneIndex = anchored
        ? (data!.todayRead ? data.statuses!.today : null)
        : next == null
            ? null
            : (doneAsync?.valueOrNull ?? const <int>{})
                .where((i) => i >= 1 && i < next)
                .fold<int?>(null, (m, i) => m == null || i > m ? i : m);
    final done = hasPlan &&
        !_readAhead &&
        doneIndex != null &&
        (anchored || (todayDone && data.completedDays > 0));
    // The sky and greeting follow the clock; `done` only changes the words.
    final part = ref.watch(dayPartProvider);
    final dark = part == DayPart.evening || part == DayPart.night;
    final mood = dark ? RoadMood.evening : RoadMood.day;
    final now = ref.watch(dayPartClockProvider)();

    final title = !done
        ? TimeGreeting.forPart(part).greeting
        : dark
            ? DailyStrings.restWell
            : DailyStrings.wellDone;
    final headText = name == null ? title : '$title, $name';
    final overSky = dark ? c.textOnEveningSky : c.textPrimary;
    final overSkySecondary = dark ? c.textOnEveningSky : c.textSecondary;

    // The tab sits inside a SafeArea; the scene bleeds up under the status bar.
    final view = View.of(context);
    final ViewPadding vp = view.padding;
    final inset = vp.top / view.devicePixelRatio;

    // Stub road ("day 1 of 9999") must never flash while the plan loads.
    if ((reading.isLoading && !reading.hasValue) ||
        (doneAsync != null && doneAsync.isLoading && !doneAsync.hasValue)) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

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

    // The collapsed panel's chip: today's day and passage, or tomorrow's once
    // today is read.
    final nextPassage = hasPlan && !data.isFinished
        ? formatPassages(data.day!.passages, bookNames)
        : '';
    final peekLabel = !hasPlan
        ? DailyStrings.choosePlan
        : data.isFinished
            ? DailyStrings.planCompleteTitle
            : done && data.day!.dayIndex > doneIndex
                ? '${DailyStrings.tomorrow} · $nextPassage'
                : '${DailyStrings.dayN(data.day!.dayIndex)} · $nextPassage';

    // At large text the chip would squeeze the greeting to a sliver: it drops
    // under it instead.
    final stackChip = MediaQuery.textScalerOf(context).scale(16) > 22;
    final streakChip = streak.isActive
        ? Padding(
            padding: stackChip
                ? const EdgeInsets.only(top: LumSpace.sm)
                : const EdgeInsets.only(left: LumSpace.md),
            child: StreakChip(
              days: streak.current,
              onTap: () => context.router.push(const StreakRoute()),
            ),
          )
        : null;

    return Align(
      alignment: Alignment.topCenter,
      // The road is drawn for a phone: on a tablet or in landscape it stays
      // phone-wide and centred rather than stretching.
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxSceneWidth),
        child: LayoutBuilder(builder: (context, box) {
          final width = box.maxWidth;
          final h = box.maxHeight;
          final k = width / RoadScene.designWidth;
          // Where the scene hands over to the panel, capped so landscape keeps
          // room for the reading.
          var panelTop =
              ((done ? 404 : 392) * k - inset).clamp(0.0, h * .55).toDouble();
          // Large text: the header below the status bar pushes the panel down
          // rather than sliding under it.
          // The measured greeting block once laid out, an estimate before.
          final headerH = _headerH ??
              _headerHeight(
                  context, headText, width, streak.isActive, stackChip);
          panelTop = math.max(panelTop, math.min(headerH, h * .7));
          // Peek: a chip above the floating tab bar; the default panel always
          // stands clear above it.
          final tabClear = LumSize.tabBar +
              math.max(vp.bottom / view.devicePixelRatio, 8) +
              12;
          final peekF = ((_peekChip + tabClear) / h).clamp(.1, .6).toDouble();
          final defaultF =
              ((h - panelTop) / h).clamp(peekF + .08, .9).toDouble();
          // Expanded stops under the greeting, never over it.
          final expandedF = math.max((h - headerH) / h, defaultF).clamp(0, 1);
          if (_snap.length != 1 || _snap.first != defaultF) {
            _snap = [defaultF];
          }
          _layout(h, inset, defaultF, peekF);
          WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeader());
          final reduce = MediaQuery.disableAnimationsOf(context);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -inset,
                left: 0,
                child: RoadScene(
                  width: width,
                  height: h + inset,
                  visibleBottom: _vb,
                  hideBack: _expanded,
                  mood: mood,
                  currentDay: currentDay,
                  totalDays: total,
                  plan: data?.plan,
                  showTomorrowTag: done,
                  statuses: data?.statuses,
                  onStopTap: data == null
                      ? null
                      : (day) => _openStop(data, day, evening: done),
                  liftedId: _lifted,
                  onLandmarkTap: data == null ? null : _openLandmark,
                ),
              ),
              // Greeting and streak: the sky's text, gone when the road
              // fills the screen.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ValueListenableBuilder<double>(
                  valueListenable: _collapse,
                  builder: (_, p, child) => IgnorePointer(
                    ignoring: p > .3,
                    // Covered by the panel (or hidden), the greeting is not
                    // for a screen reader either.
                    child: ExcludeSemantics(
                      excluding: p > .3 || p < -.05,
                      child: Opacity(
                          opacity: (1 - p * 2.5).clamp(0.0, 1.0), child: child),
                    ),
                  ),
                  child: Padding(
                    key: _headerKey,
                    padding: const EdgeInsets.fromLTRB(LumSize.screenGutter + 4,
                        24, LumSize.screenGutter + 4, LumSpace.lg),
                    child: Flex(
                      direction: stackChip ? Axis.vertical : Axis.horizontal,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Roomy(
                          expand: !stackChip,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                done
                                    ? DailyStrings.partCaps(now, part)
                                    : DailyStrings.dateCaps(now),
                                style: LumText.roadLabelCaps11
                                    .copyWith(color: overSkySecondary),
                              ),
                              const SizedBox(height: 10),
                              Semantics(
                                header: true,
                                child: Text(
                                  headText,
                                  style:
                                      LumText.title1.copyWith(color: overSky),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (streakChip != null) streakChip,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DraggableScrollableSheet(
                  controller: _sheet,
                  initialChildSize: defaultF,
                  minChildSize: peekF,
                  maxChildSize: expandedF.toDouble(),
                  snap: true,
                  snapSizes: _snap,
                  snapAnimationDuration:
                      Duration(milliseconds: reduce ? 1 : 280),
                  shouldCloseOnMinExtent: false,
                  builder: (context, scroll) => _Sheet(
                    scroll: scroll,
                    collapse: _collapse,
                    peekLabel: peekLabel,
                    onPeekTap: () => _showPanel(defaultF, reduce),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        reading.when(
                          loading: () => const SizedBox(height: 160),
                          error: (e, _) => Text(
                            DailyStrings.loadError,
                            style:
                                LumText.body.copyWith(color: c.textSecondary),
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
                                          doneIndex: doneIndex,
                                          bookNames: bookNames,
                                          streakDays: streak.current,
                                          onReadAhead: () =>
                                              setState(() => _readAhead = true),
                                        )
                                      : _Reading(
                                          reading: d,
                                          bookNames: bookNames,
                                          onChange: _choosePlan,
                                          onStart: () => _startReading(d),
                                        ),
                        ),
                        _PlanNoteCard(
                          catchUpDays: data?.catchUpDays ?? 0,
                          calendarDay: data?.statuses?.today ?? 0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ------------------------------------------------------------- the sheet
  static const double _peekChip = 56;

  /// The reading panel, in the sheet's own coordinates: [_vb] is where its top
  /// edge is in px from the scene's top (the scene keys its camera off it) and
  /// [_collapse] runs 0 (default) to 1 (peek) for the fades.
  final _sheet = DraggableScrollableController();
  late final _vb = ValueNotifier<double>(_vbNow());
  final _collapse = ValueNotifier<double>(0);
  final _expanded = ValueNotifier<bool>(false);
  double _h = 0, _inset = 0, _defaultF = .5, _peekF = .2;
  List<double> _snap = const [.5];

  /// The greeting block, measured; null until the first layout.
  final _headerKey = GlobalKey();
  double? _headerH;

  void _measureHeader() {
    final box = _headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (!mounted || box == null || !box.hasSize) return;
    if ((_headerH ?? -9) != box.size.height &&
        ((_headerH ?? 0) - box.size.height).abs() > 1) {
      setState(() => _headerH = box.size.height);
    }
  }

  /// 0 at the default size, 1 at the peek, below 0 when expanded.
  double _progress() {
    final span = _peekF - _defaultF;
    return span == 0
        ? 0
        : ((_fraction - _defaultF) / span).clamp(-1.0, 1.0).toDouble();
  }

  /// Where the road's usable area ends (px from the scene's top): the panel's
  /// top, less the peek chip as it collapses so no stop hides under it, and
  /// never above the default so the road does not scroll up behind a panel
  /// that is expanding.
  double _vbNow() {
    final raw = (1 - _fraction) * _h + _inset;
    final base = (1 - _defaultF) * _h + _inset;
    return math.max(raw - _peekChip * math.max(_progress(), 0), base);
  }

  double get _fraction => _sheet.isAttached ? _sheet.size : _defaultF;

  /// Called from build with the current box; syncs the notifiers (after the
  /// frame if the box changed, so nothing is notified mid-build).
  void _layout(double h, double inset, double defaultF, double peekF) {
    final first = _h == 0;
    final changed =
        h != _h || inset != _inset || defaultF != _defaultF || peekF != _peekF;
    _h = h;
    _inset = inset;
    _defaultF = defaultF;
    _peekF = peekF;
    if (first) {
      _vb.value = _vbNow();
      _collapse.value = 0;
    } else if (changed || !_sheet.isAttached) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    }
  }

  void _sync() {
    if (!mounted || _h == 0) return;
    _vb.value = _vbNow();
    _collapse.value = _progress();
    _expanded.value = _progress() < -.05;
  }

  void _onSheet() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    } else {
      _sync();
    }
  }

  void _showPanel(double defaultF, bool reduce) {
    if (!_sheet.isAttached) return;
    if (reduce) {
      _sheet.jumpTo(defaultF);
    } else {
      _sheet.animateTo(defaultF,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic);
    }
  }

  @override
  void initState() {
    super.initState();
    _sheet.addListener(_onSheet);
  }

  @override
  void dispose() {
    _sheet.removeListener(_onSheet);
    _sheet.dispose();
    _vb.dispose();
    _collapse.dispose();
    _expanded.dispose();
    super.dispose();
  }

  /// Height of the greeting block at the current text size, so the panel never
  /// starts over it.
  double _headerHeight(BuildContext context, String headText, double width,
      bool streak, bool stackChip) {
    final scaler = MediaQuery.textScalerOf(context);
    final p = TextPainter(
      text: TextSpan(text: headText, style: LumText.title1),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout(
        maxWidth: width -
            2 * (LumSize.screenGutter + 4) -
            (streak && !stackChip ? 120 : 0));
    final caps = TextPainter(
      text: const TextSpan(text: 'X', style: LumText.roadLabelCaps11),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    return 24 +
        4 +
        caps.height +
        10 +
        p.height +
        (streak && stackChip ? LumSpace.sm + 52 : 0) +
        LumSpace.lg;
  }

  Future<void> _choosePlan() => showPlanPickerSheet(context);

  /// A stop on the road: its sheet, then the reader if asked. Marking is only
  /// offered for the day the traveller stands on; days ahead are previews.
  Future<void> _openStop(TodaysReading d, int dayIndex,
      {required bool evening}) async {
    final day = d.plan.dayAt(dayIndex);
    if (day == null) return;
    final current = d.day?.dayIndex;
    final st = d.statuses;
    final StopStatus status;
    final DateTime? date;
    final now = DateTime.now();
    if (st != null) {
      // Anchored: the same status source the road draws from.
      final isTomorrow = evening && dayIndex == current;
      status = switch (st.of(dayIndex)) {
        DayStatus.done => StopStatus.done,
        DayStatus.catchUp => StopStatus.catchUp,
        DayStatus.today => StopStatus.today,
        DayStatus.ahead => isTomorrow ? StopStatus.tomorrow : StopStatus.ahead,
      };
      date = status == StopStatus.done || status == StopStatus.catchUp
          ? null
          : dateForDay(day: dayIndex, currentDay: st.today, today: now);
    } else {
      // The road's own rule: everything before the traveller is read, and
      // everything from them on is still ahead (even a day read past a gap).
      final isDone = d.isFinished || (current != null && dayIndex < current);
      status = isDone
          ? StopStatus.done
          : dayIndex == current
              ? (evening ? StopStatus.tomorrow : StopStatus.today)
              : StopStatus.ahead;
      date = current == null || isDone
          ? null
          : dateForDay(
              day: dayIndex,
              currentDay: current,
              today: evening ? nextDay(now) : now,
            );
    }
    final open = await showStopSheet(
      context,
      contentLoad: roadDayContent(d.plan, dayIndex),
      plan: d.plan,
      day: day,
      status: status,
      date: date,
      progressId: d.progressKey,
      bookNames: ref.read(planBookNamesProvider).valueOrNull ?? const {},
    );
    await _open(open);
  }

  String? _lifted;

  Future<void> _openLandmark(Landmark landmark, int day, Rect from) async {
    LandmarkStory? story;
    try {
      story = (await ref.read(landmarkStoriesProvider.future))[landmark.id];
    } catch (_) {
      // The retelling is a bonus; the sheet still opens with the title.
    }
    if (!mounted) return;
    ui.Image? sprite;
    final art = landmark.art;
    if (art != null) {
      try {
        sprite = (await RoadArt.load())['lm_$art'];
      } catch (_) {}
    }
    if (!mounted) return;
    if (sprite != null) setState(() => _lifted = landmark.id);
    RoadOpen? open;
    try {
      open = await showLandmarkSheet(context,
          landmark: landmark,
          story: story,
          day: day,
          sprite: sprite,
          from: sprite == null ? null : from);
    } finally {
      // Whatever happened (error, timeout, swipe), the sprite is back on the
      // road and the road repaints now.
      if (mounted && _lifted == landmark.id) setState(() => _lifted = null);
    }
    await _open(open);
  }

  Future<void> _open(RoadOpen? open) async {
    if (open == null || !mounted) return;
    final marked = await openBibleLink(
      context,
      ref,
      targetKey: open.targetKey,
      planId: open.planId,
      dayIndex: open.dayIndex,
    );
    if (marked == true && mounted) setState(() => _readAhead = false);
  }

  /// Opens the reader on today's plan day. Mark read lives there; when it was
  /// marked, "read ahead" is over and Today shows the done state.
  Future<void> _startReading(TodaysReading d) async {
    final marked = await openBibleLink(
      context,
      ref,
      targetKey: openingRefFor(d.day!),
      planId: d.progressKey,
      dayIndex: d.day!.dayIndex,
    );
    if (marked == true && mounted) setState(() => _readAhead = false);
  }
}

/// The rounded panel the reading sits on, over the lower scene. A snapping
/// bottom sheet: dragged down it melts into a small "Day N · passage" chip
/// above the tab bar so the road fills the screen; the chip (or a drag) brings
/// it back. [collapse] runs 0 (open) to 1 (chip).
const double _peekChipHeight = 64;

class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.scroll,
    required this.collapse,
    required this.peekLabel,
    required this.onPeekTap,
    required this.child,
  });

  final ScrollController scroll;
  final ValueListenable<double> collapse;
  final String peekLabel;
  final VoidCallback onPeekTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    final grab = c.textSecondary.withValues(alpha: .4);
    return ValueListenableBuilder<double>(
      valueListenable: collapse,
      child: SingleChildScrollView(
        controller: scroll,
        // Always draggable, even when the reading is shorter than the panel.
        physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics()),
        child: ValueListenableBuilder<double>(
          valueListenable: collapse,
          // Hidden content must not be tappable; the scroll view itself still
          // takes the drag that opens the panel again.
          builder: (_, p, child) =>
              IgnorePointer(ignoring: p > .3, child: child),
          // 120 at the bottom clears the floating tab bar.
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 120),
            child: child,
          ),
        ),
      ),
      builder: (context, p, content) {
        final open = (1 - p).clamp(0.0, 1.0);
        final chip = ((p - .6) / .4).clamp(0.0, 1.0);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.scenePanel.withValues(alpha: open),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: c.sceneShadow
                            .withValues(alpha: c.sceneShadow.a * open),
                        blurRadius: 28,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // At the peek only a narrow strip around the chip takes touches;
            // the rest of the (transparent) sheet lets the road through.
            Positioned.fill(
              child: LayoutBuilder(
                builder: (_, box) => Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: p > .9 ? _peekChipHeight : box.maxHeight,
                    child: Opacity(
                        opacity: (1 - p * 2.5).clamp(0.0, 1.0), child: content),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 9,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Opacity(
                  opacity: (1 - p * 2).clamp(0.0, 1.0),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: grab,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (chip > 0)
              Positioned(
                top: 6,
                left: LumSpace.lg,
                right: LumSpace.lg,
                child: IgnorePointer(
                  ignoring: chip < .5,
                  child: Opacity(
                    opacity: chip,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: _PeekChip(label: peekLabel, onTap: onPeekTap),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The collapsed panel: today's day and passage, with a chevron that says it
/// opens upwards.
class _PeekChip extends StatelessWidget {
  const _PeekChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Semantics(
        button: true,
        label: label,
        hint: DailyStrings.opensReading,
        excludeSemantics: true,
        onTap: onTap,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            height: LumSize.touchTarget,
            padding: const EdgeInsets.symmetric(horizontal: LumSpace.lg),
            decoration: BoxDecoration(
              color: c.scenePanel,
              borderRadius: BorderRadius.circular(LumRadius.full),
              border: Border.all(color: c.borderSubtle),
              boxShadow: [
                BoxShadow(
                    color: c.sceneShadow,
                    blurRadius: 14,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.keyboard_arrow_up_rounded,
                    size: LumSize.iconSm, color: c.textSecondary),
                const SizedBox(width: LumSpace.sm),
                Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LumText.footnoteEmphasized
                          .copyWith(color: c.textPrimary)),
                ),
              ],
            ),
          ),
        ),
      ),
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
    required this.onStart,
  });

  final TodaysReading reading;
  final Map<String, String> bookNames;
  final VoidCallback onChange;
  final VoidCallback onStart;

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
        LayoutBuilder(
          builder: (context, box) {
            final scaler = MediaQuery.textScalerOf(context);
            double width(String text, TextStyle style, [TextScaler? sc]) {
              final p = TextPainter(
                text: TextSpan(text: text, style: style),
                textDirection: TextDirection.ltr,
                textScaler: sc ?? scaler,
              )..layout();
              return p.width;
            }

            final numberBlock = Semantics(
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
            );
            final numberWidth = width(
              '${day.dayIndex}',
              LumText.roadDisplayHero120,
              TextScaler.noScaling,
            );
            final beside = box.maxWidth - numberWidth - 22;
            // Never break a word: try 34 beside the number, then 24, then give
            // the passage the full row under the number.
            final TextStyle style;
            final bool below;
            var shrink = false;
            if (width(passage, LumText.roadTitleLarge34) <= beside) {
              style = LumText.roadTitleLarge34;
              below = false;
            } else if (width(passage, LumText.roadTitleSmall24) <= beside) {
              style = LumText.roadTitleSmall24;
              below = false;
            } else {
              final longest = passage
                  .split(' ')
                  .reduce((a, b) => a.length >= b.length ? a : b);
              style = width(longest, LumText.roadTitleLarge34) <= box.maxWidth
                  ? LumText.roadTitleLarge34
                  : LumText.roadTitleSmall24;
              // Even 24 can't hold the longest word at this width and text
              // size: scale the line down rather than break the word.
              shrink = width(longest, style) > box.maxWidth;
              below = true;
            }
            final info = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DailyStrings.todaysReading.toUpperCase(),
                    style: LumText.roadLabelCaps11
                        .copyWith(color: c.textSecondary)),
                const SizedBox(height: 4),
                shrink
                    ? FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(passage,
                            style: style.copyWith(color: c.textPrimary)),
                      )
                    : Text(passage,
                        style: style.copyWith(color: c.textPrimary)),
                const SizedBox(height: 4),
                Text(DailyStrings.chapters(_chapters(day)),
                    style: LumText.footnote.copyWith(color: c.textSecondary)),
              ],
            );
            if (below) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [numberBlock, const SizedBox(height: 8), info],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                numberBlock,
                const SizedBox(width: 22),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: info,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        LumButton(
          label: DailyStrings.startReading,
          icon: const Icon(Icons.menu_book_outlined),
          onPressed: onStart,
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _TextAction(
              label:
                  '${DailyStrings.dayOfTotal(day.dayIndex, reading.plan.dayCount)} · ${DailyStrings.allDays}',
              onTap: () =>
                  context.router.push(PlanDaysRoute(planId: reading.plan.id)),
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
    required this.doneIndex,
    required this.bookNames,
    required this.streakDays,
    required this.onReadAhead,
  });

  final TodaysReading reading;
  final int doneIndex;
  final Map<String, String> bookNames;
  final int streakDays;
  final VoidCallback onReadAhead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lum;
    final next = reading.day!.dayIndex;
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
        if (next > doneIndex)
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
                style: LumText.footnote.copyWith(
                    color: streak ? c.tileOnStreak : c.textSecondary)),
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

/// [child] filling the row ([Expanded]) or just itself when stacked.
class _Roomy extends StatelessWidget {
  const _Roomy({required this.expand, required this.child});

  final bool expand;
  final Widget child;

  @override
  Widget build(BuildContext context) => expand ? Expanded(child: child) : child;
}

/// Small cards under the panel content: the countdown for a locked plan the
/// person asked to see on Today, a Join card once it opens (until they join or
/// dismiss), and the kind catch-up line. Renders nothing when none applies.
class _PlanNoteCard extends ConsumerWidget {
  const _PlanNoteCard({required this.catchUpDays, required this.calendarDay});

  final int catchUpDays;
  final int calendarDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lum;
    final fallbackToday = ref.watch(planTodayProvider);
    final DateTime today =
        dateFromKey(ref.watch(todayKeyProvider)) ?? fallbackToday;
    final reminders = ref.watch(planRemindersProvider);
    final plans = ref.watch(availablePlansProvider).valueOrNull ?? const [];
    final lines = <String>[];
    final joinable = <ReadingPlan>[];
    for (final p in plans) {
      if (!reminders.contains(p.id)) continue;
      final schedule = PlanSchedule(p);
      if (!schedule.isFixed) continue;
      if (schedule.isLocked(today)) {
        lines.add(DailyStrings.yearStartsIn(p.title, schedule.daysToGo(today)));
        continue;
      }
      final sub = ref.watch(planSubscriptionProvider(p.id)).valueOrNull;
      if (!schedule.runFor(sub?.startDateKey, today).joined) joinable.add(p);
    }
    if (catchUpDays > 0) {
      lines.add(DailyStrings.catchUp(calendarDay, catchUpDays));
    }
    if (lines.isEmpty && joinable.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: LumSpace.lg),
      child: Container(
        padding: const EdgeInsets.all(LumSpace.md),
        decoration: BoxDecoration(
          color: c.bgSurfaceSunken,
          borderRadius: BorderRadius.circular(LumRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in lines)
              Text(line,
                  style: LumText.subheadline.copyWith(color: c.textSecondary)),
            for (final p in joinable) ...[
              Text(
                  PlanSchedule(p).calendarDay(today) == 1
                      ? DailyStrings.yearOpenToday(p.title)
                      : DailyStrings.yearOpenNow(
                          p.title, PlanSchedule(p).calendarDay(today)),
                  style: LumText.subheadline.copyWith(color: c.textPrimary)),
              const SizedBox(height: LumSpace.sm),
              Row(children: [
                Expanded(
                  child: LumButton(
                    label: DailyStrings.joinCaps,
                    onPressed: () => ref.read(startPlanProvider)(p),
                  ),
                ),
                const SizedBox(width: LumSpace.sm),
                TextButton(
                  onPressed: () => ref
                      .read(planRemindersProvider.notifier)
                      .toggle(p.id, false),
                  child: const Text(DailyStrings.dismiss),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}
