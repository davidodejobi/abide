import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/database/database_provider.dart';
import 'package:openbaptisthymnal/core/theme/app_colors.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/features/bible/ui/open_bible_link.dart';

import '../domain/passage_label.dart';
import '../domain/plan_progress.dart';
import '../domain/reading_plan.dart';
import '../providers/daily_providers.dart';

/// The whole plan, every day of it.
///
/// Without this the plan is a keyhole: you can see today and nothing else. You
/// cannot go back to a passage you liked, cannot re-read the day you rushed,
/// cannot show someone what you have been reading, and cannot tell how far in
/// you are except by a number the app hands you. A reading plan people cannot
/// look at is a reading plan they cannot trust.
///
/// Opens scrolled to the day you are on, because that is the row you came for.
@RoutePage()
class PlanDaysPage extends ConsumerStatefulWidget {
  const PlanDaysPage({super.key, required this.planId});

  final String planId;

  @override
  ConsumerState<PlanDaysPage> createState() => _PlanDaysPageState();
}

class _PlanDaysPageState extends ConsumerState<PlanDaysPage> {
  /// Fixed so the initial jump can be computed rather than guessed. Every row is
  /// the same two lines of text.
  static const _rowHeight = 76.0;

  final _controller = ScrollController();
  bool _jumped = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _jumpToCurrentDay(int dayIndex, int dayCount) {
    if (_jumped || !_controller.hasClients) return;
    _jumped = true;

    // Centre the row rather than pin it to the top, so the days either side are
    // visible -- what you came to look at is usually "where am I", and that is a
    // question about neighbours.
    final viewport = _controller.position.viewportDimension;
    final target = (dayIndex - 1) * _rowHeight - (viewport / 2) + _rowHeight;
    _controller.jumpTo(
      target.clamp(0.0, _controller.position.maxScrollExtent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(planByIdProvider(widget.planId));
    final done = ref.watch(planProgressProvider(widget.planId)).valueOrNull ??
        const <int>{};
    final bookNames = ref.watch(planBookNamesProvider).valueOrNull ?? const {};

    return Scaffold(
      appBar: AppBar(
        title: Text(planAsync.valueOrNull?.title ?? 'Plan'),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, _) => const Center(child: Text("This plan couldn't load.")),
        data: (plan) {
          final current = nextPlanDayIndex(done, plan.dayCount);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _jumpToCurrentDay(current ?? plan.dayCount, plan.dayCount);
          });

          return ListView.builder(
            controller: _controller,
            itemCount: plan.dayCount,
            itemExtent: _rowHeight,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemBuilder: (context, i) {
              final day = plan.days[i];
              return _DayRow(
                plan: plan,
                day: day,
                bookNames: bookNames,
                isDone: done.contains(day.dayIndex),
                isCurrent: day.dayIndex == current,
              );
            },
          );
        },
      ),
    );
  }
}

class _DayRow extends ConsumerWidget {
  const _DayRow({
    required this.plan,
    required this.day,
    required this.bookNames,
    required this.isDone,
    required this.isCurrent,
  });

  final ReadingPlan plan;
  final PlanDay day;
  final Map<String, String> bookNames;
  final bool isDone;
  final bool isCurrent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isCurrent
            ? AppColors.secondary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          // Tapping the row reads it. Marking it done is the checkbox -- a tap
          // that both opens a passage AND silently claims you read it would be
          // lying on your behalf.
          onTap: () => openBibleLink(
            context,
            ref,
            targetKey: openingRefFor(day),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Day ${day.dayIndex}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isCurrent
                              ? AppColors.secondary
                              : colorScheme.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatPassages(day.passages, bookNames),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isDone
                              ? colorScheme.onSurface.withValues(alpha: 0.55)
                              : colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                // You can UN-mark a day here, but you cannot mark one.
                //
                // Not a trust exercise -- a marking control here would simply be
                // redundant. Progress is progress-driven, so the Today card
                // always shows the oldest day you have not read: catching up
                // already walks you through the missed days in order, without
                // ever coming here. All a checkbox would add is a way to claim
                // days you never opened, which is the one thing a reading plan
                // must not make easy.
                //
                // Un-marking stays, because correcting a mis-tap must always be
                // easy. A record you cannot fix is a record you stop trusting.
                if (isDone)
                  IconButton(
                    icon: const Icon(Icons.check_circle),
                    color: AppColors.secondary,
                    tooltip: 'Mark as unread',
                    onPressed: () => ref
                        .read(readingPlansDaoProvider)
                        .unmarkPlanDay(
                          planId: plan.id,
                          dayIndex: day.dayIndex,
                        ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.circle_outlined,
                      size: 20,
                      color: colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
