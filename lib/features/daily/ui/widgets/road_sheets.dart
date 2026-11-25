import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
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
    ),
  );
  if (!flight.backStarted) flight.finish();
  await flight.settled;
  return open;
}

Future<RoadOpen?> _show(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<RoadOpen>(
    context: context,
    isScrollControlled: true,
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
  });

  final ShowcaseFlight? flight;

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
    final s = story;
    return _SheetBody(
      children: [
        if (sprite != null && landmark.art != null)
          LandmarkShowcase(
            art: landmark.art!,
            sprite: sprite!,
            eyebrow: '${DailyStrings.dayN(day)} · ${landmark.ref}',
            title: landmark.title,
            flight: flight,
          )
        else ...[
          Text('${DailyStrings.dayN(day)} · ${landmark.ref}'.toUpperCase(),
              style: LumText.roadLabelCaps11.copyWith(color: c.textSecondary)),
          const SizedBox(height: LumSpace.xs),
          Semantics(
            header: true,
            child: Text(landmark.title,
                style: LumText.title1.copyWith(color: c.textPrimary)),
          ),
        ],
        const SizedBox(height: LumSpace.lg),
        if (s == null)
          Text(landmark.short,
              style: LumText.body.copyWith(color: c.textPrimary))
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
                    style: LumText.roadLabelCaps11
                        .copyWith(color: c.textSecondary)),
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
      ],
    );
  }
}
