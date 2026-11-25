import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/utils/services/share_service.dart';
import 'package:openbaptisthymnal/core/widgets/lum_button.dart';

import '../../domain/passage_label.dart';
import '../../domain/plan_progress.dart';
import '../../domain/reading_plan.dart';
import '../../domain/road_days.dart';
import '../../domain/road_landmarks.dart';
import '../daily_strings.dart';
import 'landmark_showcase.dart';

/// What a road sheet asks the Today tab to open: the reader at [targetKey],
/// with Mark read only when [planId] and [dayIndex] are given.
class RoadOpen {
  const RoadOpen(this.targetKey, {this.planId, this.dayIndex});

  final String targetKey;
  final String? planId;
  final int? dayIndex;
}

enum StopStatus {
  done,
  catchUp,
  today,
  tomorrow,
  ahead;

  /// The reading the traveller stands on: the one Mark read applies to.
  bool get readable => this == today || this == tomorrow || this == catchUp;
}

/// A stop on the road: the day, the date it falls on, its passages, and how to
/// read it. A day still ahead is a preview (no Mark read); a day already read
/// can be read again.
Future<RoadOpen?> showStopSheet(
  BuildContext context, {
  required ReadingPlan plan,
  required PlanDay day,
  required StopStatus status,
  required DateTime? date,
  required Map<String, String> bookNames,
  String? progressId,
}) {
  return _show(
    context,
    (_) => StopSheet(
      progressId: progressId,
      plan: plan,
      day: day,
      status: status,
      date: date,
      bookNames: bookNames,
    ),
  );
}

/// A landmark on the road: what happened there, why it matters, and a way to
/// read it or pass it on.
Future<RoadOpen?> showLandmarkSheet(
  BuildContext context, {
  required Landmark landmark,
  required LandmarkStory? story,
  required int day,
  ui.Image? sprite,
  Rect? from,
  VoidCallback? onShareCard,
}) async {
  // [from] is where the sprite stands on the road (global): it flies from
  // there into the sheet and back. Resolves once it has landed home again.
  final flight = ShowcaseFlight(from);
  final open = await _show(
    context,
    (_) => LandmarkSheet(
      landmark: landmark,
      story: story,
      day: day,
      sprite: sprite,
      flight: flight,
      onShareCard: onShareCard,
    ),
    // The road stays visible above it.
    maxHeightFraction: sprite != null && landmark.art != null ? .78 : null,
  );
  if (!flight.backStarted) flight.finish();
  await flight.settled;
  return open;
}

Future<RoadOpen?> _show(BuildContext context, WidgetBuilder builder,
    {double? maxHeightFraction}) {
  return showModalBottomSheet<RoadOpen>(
    context: context,
    isScrollControlled: true,
    constraints: maxHeightFraction == null
        ? null
        : BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * maxHeightFraction),
    showDragHandle: true,
    useSafeArea: true,
    backgroundColor: context.lum.bgPage,
    builder: builder,
  );
}

/// The shared sheet body: scrolls, so large text never pushes the buttons off
/// screen.
class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            LumSize.screenGutter, 0, LumSize.screenGutter, LumSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class StopSheet extends StatelessWidget {
  const StopSheet({
    super.key,
    required this.plan,
    required this.day,
    required this.status,
    required this.date,
    required this.bookNames,
    this.progressId,
  });

  /// Where this plan's progress is stored (the plan id unless anchored).
  final String? progressId;
  final ReadingPlan plan;
  final PlanDay day;
  final StopStatus status;
  final DateTime? date;
  final Map<String, String> bookNames;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    final (label, icon, color) = switch (status) {
      StopStatus.done => (
          DailyStrings.sheetDone,
          Icons.check_circle_rounded,
          c.iconSuccess
        ),
      StopStatus.catchUp => (
          DailyStrings.sheetCatchUp,
          Icons.history_rounded,
          c.textSecondary
        ),
      StopStatus.today => (
          DailyStrings.sheetToday,
          Icons.wb_twilight_rounded,
          c.textPrimary
        ),
      StopStatus.tomorrow => (
          DailyStrings.tomorrow,
          Icons.wb_twilight_rounded,
          c.textPrimary
        ),
      StopStatus.ahead => (
          DailyStrings.sheetAhead,
          Icons.schedule_rounded,
          c.textSecondary
        ),
    };
    final when = date == null || status == StopStatus.done
        ? label
        : '$label · ${DailyStrings.dateLong(date!)}';
    return _SheetBody(
      children: [
        Text(DailyStrings.dayOfTotal(day.dayIndex, plan.dayCount).toUpperCase(),
            style: LumText.roadLabelCaps11.copyWith(color: c.textSecondary)),
        const SizedBox(height: LumSpace.xs),
        Semantics(
          header: true,
          child: Text(DailyStrings.dayN(day.dayIndex),
              style: LumText.title1.copyWith(color: c.textPrimary)),
        ),
        const SizedBox(height: LumSpace.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: LumSize.iconSm, color: color),
            ),
            const SizedBox(width: LumSpace.sm),
            Expanded(
              child: Text(when,
                  style: LumText.subheadline.copyWith(color: c.textSecondary)),
            ),
          ],
        ),
        if (status == StopStatus.ahead) ...[
          const SizedBox(height: LumSpace.xs),
          Text(DailyStrings.sheetDateNote,
              style: LumText.footnote.copyWith(color: c.textSecondary)),
        ],
        const SizedBox(height: LumSpace.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(LumSpace.lg),
          decoration: BoxDecoration(
            color: c.bgSurface,
            borderRadius: BorderRadius.circular(LumRadius.lg),
            border: Border.all(color: c.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, p) in day.passages.indexed) ...[
                if (i > 0) const SizedBox(height: LumSpace.md),
                Text(formatPassages([p], bookNames),
                    style: LumText.headline.copyWith(color: c.textPrimary)),
                const SizedBox(height: 2),
                Text(DailyStrings.chapters(p.end.chapter - p.start.chapter + 1),
                    style: LumText.footnote.copyWith(color: c.textSecondary)),
              ],
            ],
          ),
        ),
        const SizedBox(height: LumSpace.xl),
        LumButton(
          label: switch (status) {
            StopStatus.today || StopStatus.tomorrow => DailyStrings.readDay,
            StopStatus.catchUp => DailyStrings.readCatchUp,
            StopStatus.done => DailyStrings.readAgain,
            StopStatus.ahead => DailyStrings.previewDay,
          },
          icon: const Icon(Icons.menu_book_outlined),
          kind:
              status.readable ? LumButtonKind.primary : LumButtonKind.secondary,
          onPressed: () => Navigator.of(context).pop(RoadOpen(
            openingRefFor(day),
            // Only today's reading can be marked from the road: a day ahead
            // is a preview, and one already read has been marked.
            planId: status.readable ? (progressId ?? plan.id) : null,
            dayIndex: status.readable ? day.dayIndex : null,
          )),
        ),
      ],
    );
  }
}

class LandmarkSheet extends StatelessWidget {
  const LandmarkSheet({
    super.key,
    required this.landmark,
    required this.story,
    required this.day,
    this.sprite,
    this.flight,
    this.onShareCard,
  });

  final ShowcaseFlight? flight;

  /// Opens the share-card composer for this landmark; null hides the button.
  final VoidCallback? onShareCard;

  /// The landmark's picture from the road, shown at the top; null when it has
  /// none yet.
  final ui.Image? sprite;

  final Landmark landmark;
  final LandmarkStory? story;
  final int day;

  /// What goes out when shared: our own retelling, never the verse text.
  String get shareText {
    final s = story;
    return [
      '${landmark.title} (${landmark.ref})',
      if (s != null) ...[s.story, s.why] else landmark.short,
    ].join('\n\n');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    final showcase = sprite != null && landmark.art != null;
    final rest = _rest(context);
    if (showcase) {
      return LandmarkShowcase(
        art: landmark.art!,
        sprite: sprite!,
        eyebrow: '${DailyStrings.dayN(day)} · ${landmark.ref}',
        title: landmark.title,
        flight: flight,
        builder: (context, stage, text) => _ShowcaseLayout(
          stage: stage,
          text: text,
          rest: rest,
          onClose: () => Navigator.of(context).pop(),
        ),
      );
    }
    return _SheetBody(
      children: [
        Text('${DailyStrings.dayN(day)} · ${landmark.ref}'.toUpperCase(),
            style: LumText.roadLabelCaps11.copyWith(color: c.textSecondary)),
        const SizedBox(height: LumSpace.xs),
        Semantics(
          header: true,
          child: Text(landmark.title,
              style: LumText.title1.copyWith(color: c.textPrimary)),
        ),
        const SizedBox(height: LumSpace.lg),
        ...rest,
      ],
    );
  }

  /// What follows the title: the retelling, why it matters, Read and Share.
  List<Widget> _rest(BuildContext context) {
    final c = context.lum;
    final s = story;
    return [
      if (s == null)
        Text(landmark.short, style: LumText.body.copyWith(color: c.textPrimary))
      else ...[
        Text(DailyStrings.whatHappened,
            style: LumText.roadLabelCaps11.copyWith(color: c.textSecondary)),
        const SizedBox(height: LumSpace.sm),
        Text(s.story, style: LumText.body.copyWith(color: c.textPrimary)),
        const SizedBox(height: LumSpace.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(LumSpace.lg),
          decoration: BoxDecoration(
            color: c.bgSurface,
            borderRadius: BorderRadius.circular(LumRadius.lg),
            border: Border.all(color: c.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DailyStrings.whyItMatters,
                  style:
                      LumText.roadLabelCaps11.copyWith(color: c.textSecondary)),
              const SizedBox(height: LumSpace.sm),
              Text(s.why,
                  style: LumText.callout.copyWith(color: c.textPrimary)),
            ],
          ),
        ),
      ],
      const SizedBox(height: LumSpace.xl),
      LumButton(
        label: DailyStrings.readRef(landmark.ref),
        icon: const Icon(Icons.menu_book_outlined),
        onPressed: () =>
            Navigator.of(context).pop(RoadOpen(landmark.openingKey)),
      ),
      const SizedBox(height: LumSpace.sm),
      Builder(
        builder: (context) => LumButton(
          label: DailyStrings.share,
          icon: const Icon(Icons.ios_share_rounded),
          kind: LumButtonKind.secondary,
          onPressed: () {
            // iPad needs an anchor for the share popover.
            final box = context.findRenderObject() as RenderBox?;
            ShareService().shareText(
              shareText,
              sharePositionOrigin: box == null || !box.hasSize
                  ? null
                  : box.localToGlobal(Offset.zero) & box.size,
            );
          },
        ),
      ),
      if (onShareCard != null) ...[
        const SizedBox(height: LumSpace.sm),
        LumButton(
          label: DailyStrings.shareLandmarkCard,
          icon: const Icon(Icons.image_outlined),
          kind: LumButtonKind.secondary,
          onPressed: onShareCard,
        ),
      ],
    ];
  }
}

/// A round close button with a 48 pt target; it closes the sheet the same way
/// a swipe does, so the sprite flies home.
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Semantics(
      button: true,
      label: DailyStrings.close,
      excludeSemantics: true,
      onTap: onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.bgSurface,
                border: Border.all(color: c.borderSubtle),
              ),
              child: Icon(Icons.close_rounded, size: 20, color: c.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

/// The showcase sheet's layout. Only the stage is pinned, scaled down to leave
/// the story at least [_minBody] pt; the title scrolls with the story. When
/// even that does not fit (landscape, huge text) everything scrolls. The Close
/// button is always pinned top-right.
class _ShowcaseLayout extends StatelessWidget {
  const _ShowcaseLayout({
    required this.stage,
    required this.text,
    required this.rest,
    required this.onClose,
  });

  final Widget stage, text;
  final List<Widget> rest;
  final VoidCallback onClose;

  static const _minBody = 180.0;
  static const _stageH = LandmarkShowcase.stageHeight;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: LayoutBuilder(builder: (context, box) {
        final max = box.maxHeight.isFinite ? box.maxHeight : double.infinity;
        final stageH = math.min(_stageH, max * .4);
        final pinned = max.isInfinite || max - stageH >= _minBody;
        final width = box.maxWidth - 2 * LumSize.screenGutter;
        Widget scaled(double h) => SizedBox(
              width: width,
              height: h,
              child: FittedBox(
                fit: BoxFit.fill,
                child: SizedBox(
                    width: width * _stageH / h, height: _stageH, child: stage),
              ),
            );
        final body = SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              LumSize.screenGutter, 0, LumSize.screenGutter, LumSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!pinned) scaled(_stageH),
              const SizedBox(height: LumSpace.md),
              text,
              const SizedBox(height: LumSpace.sm),
              ...rest,
            ],
          ),
        );
        return Stack(
          children: [
            pinned
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: LumSize.screenGutter),
                        child: scaled(stageH),
                      ),
                      Flexible(child: body),
                    ],
                  )
                : body,
            Positioned(
              top: 0,
              right: LumSize.screenGutter - 8,
              child: _CloseButton(onPressed: onClose),
            ),
          ],
        );
      }),
    );
  }
}
