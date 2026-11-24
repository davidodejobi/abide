import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/database_provider.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';

import '../data/plan_local_source.dart';
import '../domain/date_key.dart';
import '../domain/plan_progress.dart';
import '../domain/reading_plan.dart';
import '../domain/streak.dart';

/// USFM code -> book name, in the edition the reader is currently using, so a
/// Yoruba reader sees Yoruba book names on an English-authored plan. The plan
/// itself stores only codes, which is what lets one plan serve every
/// translation.
final planBookNamesProvider = FutureProvider<Map<String, String>>((ref) async {
  final edition = ref.watch(primaryEditionProvider);
  final manifest = await ref.watch(bibleManifestProvider(edition).future);
  return {for (final book in manifest.books) book.code: book.name};
});

final planLocalSourceProvider = Provider<PlanLocalSource>(
  (ref) => const PlanLocalSource(),
);

/// Every bundled plan, for the picker.
final availablePlansProvider = FutureProvider<List<ReadingPlan>>(
  (ref) => ref.watch(planLocalSourceProvider).loadAll(),
);

final planByIdProvider = FutureProvider.family<ReadingPlan, String>(
  (ref, planId) => ref.watch(planLocalSourceProvider).load(planId),
);

/// Days the user has completed. The set the streak is derived from.
final completedDayKeysProvider = StreamProvider<Set<String>>(
  (ref) => ref.watch(readingPlansDaoProvider).watchCompletedDayKeys(),
);

/// The plan the user is following, or null if they have not picked one.
final activePlanSubscriptionProvider = StreamProvider<PlanSubscription?>(
  (ref) => ref.watch(readingPlansDaoProvider).watchActivePlan(),
);

/// Which days of the active plan are done.
final planProgressProvider = StreamProvider.family<Set<int>, String>(
  (ref, planId) =>
      ref.watch(readingPlansDaoProvider).watchCompletedDayIndexes(planId),
);

/// The streak, recomputed from the completed days on every change.
///
/// Derived, never stored. `computeStreak` is pure, so this provider is just the
/// wiring: the clock is read here, at the edge, and nowhere below.
final streakProvider = Provider<StreakResult>((ref) {
  final days = ref.watch(completedDayKeysProvider).valueOrNull ?? const {};
  return computeStreak(days, todayKey: todayKey());
});

/// Whether today is already marked read. Drives the "Mark as read" button's
/// state, and is deliberately separate from the streak: a day still in progress
/// is not a missed day.
final isTodayCompleteProvider = Provider<bool>(
  (ref) => ref.watch(streakProvider).completedToday,
);

/// Today's reading: the first day of the active plan the user has not finished.
///
/// Null when there is no active plan, or when the plan is finished -- two very
/// different states that the UI must not conflate, so it checks
/// [activePlanSubscriptionProvider] to tell them apart.
final todaysReadingProvider = FutureProvider<TodaysReading?>((ref) async {
  final subscription =
      await ref.watch(activePlanSubscriptionProvider.future);
  if (subscription == null) return null;

  final plan = await ref.watch(planByIdProvider(subscription.planId).future);
  final done = await ref.watch(planProgressProvider(subscription.planId).future);

  final next = nextPlanDayIndex(done, plan.dayCount);
  if (next == null) {
    return TodaysReading(plan: plan, day: null, completedDays: done.length);
  }

  return TodaysReading(
    plan: plan,
    day: plan.dayAt(next),
    completedDays: done.length,
  );
});

/// What the "Today's reading" card renders.
class TodaysReading {
  const TodaysReading({
    required this.plan,
    required this.day,
    required this.completedDays,
  });

  final ReadingPlan plan;

  /// The day to read next, or null when the plan is finished.
  final PlanDay? day;

  final int completedDays;

  bool get isFinished => day == null;

  /// 0.0 to 1.0. Guarded against an empty plan, which cannot happen today but
  /// would divide by zero if a future plan ever shipped with no days.
  double get progress =>
      plan.dayCount == 0 ? 0 : completedDays / plan.dayCount;
}
