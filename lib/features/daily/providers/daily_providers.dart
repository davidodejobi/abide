import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/database_provider.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/core/utils/day_part_provider.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';

import '../data/plan_local_source.dart';
import '../domain/date_key.dart';
import '../domain/plan_progress.dart';
import '../domain/plan_schedule.dart';
import '../domain/reading_plan.dart';
import '../domain/road_days.dart';
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

/// What happened at each landmark on the road, keyed by landmark id (bundled
/// `landmark_stories.json`, our own retellings).
final landmarkStoriesProvider = FutureProvider<Map<String, LandmarkStory>>(
  (ref) async => parseLandmarkStories(
      await rootBundle.loadString('assets/images/road/landmark_stories.json')),
);

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

/// Today's date key. Moves at local midnight and on app resume, so anything
/// derived from "today" rolls over without a restart.
final todayKeyProvider =
    NotifierProvider<TodayKeyNotifier, String>(TodayKeyNotifier.new);

class TodayKeyNotifier extends Notifier<String> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  String build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      _timer?.cancel();
      WidgetsBinding.instance.removeObserver(this);
    });
    _schedule();
    return _today();
  }

  // One clock for every date in the app, so tests can set the day.
  String _today() => todayKey(ref.read(dayPartClockProvider)());

  void _schedule() {
    _timer?.cancel();
    final now = ref.read(dayPartClockProvider)();
    // A second past midnight, so the timer never fires on the old day.
    _timer =
        Timer(nextDay(now).difference(now) + const Duration(seconds: 1), () {
      refresh();
    });
  }

  void refresh() {
    state = _today();
    _schedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }
}

/// Today as a local-midnight date, moving with [todayKeyProvider].
final planTodayProvider = Provider<DateTime>(
  (ref) => dateFromKey(ref.watch(todayKeyProvider)) ?? DateTime.now(),
);

/// Plans the user asked to be reminded about, by plan id. Stored locally only:
/// the app has no notification package yet, so this flag is what a scheduled
/// notification would read, and what the Today countdown card keys off.
final planRemindersProvider =
    NotifierProvider<PlanRemindersNotifier, Set<String>>(
        PlanRemindersNotifier.new);

class PlanRemindersNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => ref.watch(storageServiceProvider).getPlanReminders();

  void toggle(String planId, bool on) {
    state = on ? {...state, planId} : ({...state}..remove(planId));
    ref.read(storageServiceProvider).savePlanReminders(state);
  }
}

/// Plan days of [planId] completed today (by `completedAt`), read-only. The
/// "done" panel names one of these instead of guessing it is `next - 1`.
final planDaysDoneTodayProvider =
    StreamProvider.family<Set<int>, String>((ref, planId) {
  final today = ref.watch(todayKeyProvider);
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.planDayProgress)..where((t) => t.planId.equals(planId)))
      .watch()
      .map((rows) => {
            for (final r in rows)
              if (dayKey(r.completedAt) == today) r.dayIndex,
          });
});

/// The streak, recomputed from the completed days on every change.
///
/// Derived, never stored. `computeStreak` is pure, so this provider is just the
/// wiring: the clock is read here, at the edge, and nowhere below.
final streakProvider = Provider<StreakResult>((ref) {
  final days = ref.watch(completedDayKeysProvider).valueOrNull ?? const {};
  return computeStreak(days, todayKey: ref.watch(todayKeyProvider));
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
  final subscription = await ref.watch(activePlanSubscriptionProvider.future);
  if (subscription == null) return null;

  final plan = await ref.watch(planByIdProvider(subscription.planId).future);
  final done =
      await ref.watch(planProgressProvider(subscription.planId).future);

  final schedule = PlanSchedule(plan);
  final today = ref.watch(planTodayProvider);
  // A fixed-start plan from a past year is a finished run, not today's plan:
  // show the picker so they can join this year's.
  if (schedule.isFixed &&
      !schedule.isCurrentRun(subscription.startDateKey, today)) {
    return null;
  }

  final next = schedule.isFixed
      ? schedule.nextDay(done, subscription.startDateKey)
      : nextPlanDayIndex(done, plan.dayCount);
  if (next == null) {
    return TodaysReading(plan: plan, day: null, completedDays: done.length);
  }

  return TodaysReading(
    plan: plan,
    day: plan.dayAt(next),
    completedDays: done.length,
    catchUpDays: schedule.isFixed ? schedule.catchUpCount(done, today) : 0,
  );
});

/// What the "Today's reading" card renders.
class TodaysReading {
  const TodaysReading({
    required this.plan,
    required this.day,
    required this.completedDays,
    this.catchUpDays = 0,
  });

  final ReadingPlan plan;

  /// The day to read next, or null when the plan is finished.
  final PlanDay? day;

  final int completedDays;

  /// Unread days before today's calendar day on a fixed-start plan. Offered as
  /// catch-up, never as missed.
  final int catchUpDays;

  bool get isFinished => day == null;

  /// 0.0 to 1.0. Guarded against an empty plan, which cannot happen today but
  /// would divide by zero if a future plan ever shipped with no days.
  double get progress => plan.dayCount == 0 ? 0 : completedDays / plan.dayCount;
}

/// Marks a plan day read in the one transaction Today uses: the calendar day
/// feeds the streak, the plan day advances the plan. The UI calls this rather
/// than reaching for the DAO.
final markPlanDayReadProvider =
    Provider<Future<void> Function(String planId, int dayIndex)>((ref) {
  return (planId, dayIndex) {
    final now = ref.read(dayPartClockProvider)();
    return ref.read(readingPlansDaoProvider).markReadingComplete(
          dateKey: dayKey(now),
          source: 'plan',
          planId: planId,
          dayIndex: dayIndex,
          completedAt: now,
        );
  };
});

/// Starts [plan] for the person, the one path the picker and onboarding share.
///
/// A locked plan is refused. A fixed-start plan keeps its original join date
/// while the run is current (re-picking must not move a 1 Jan joiner's floor to
/// today), and starts clean when the year has rolled over.
final startPlanProvider =
    Provider<Future<void> Function(ReadingPlan plan)>((ref) {
  return (plan) async {
    final today = ref.read(planTodayProvider);
    final schedule = PlanSchedule(plan);
    if (schedule.isLocked(today)) return;

    final db = ref.read(appDatabaseProvider);
    final dao = ref.read(readingPlansDaoProvider);
    var startKey = dayKey(today);
    if (schedule.isFixed) {
      final existing = await (db.select(db.planSubscriptions)
            ..where((t) => t.planId.equals(plan.id)))
          .getSingleOrNull();
      if (existing != null) {
        if (schedule.isCurrentRun(existing.startDateKey, today)) {
          startKey = existing.startDateKey;
        } else {
          await dao.clearPlanProgress(plan.id);
        }
      }
    }
    await dao.startPlan(planId: plan.id, startDateKey: startKey);
  };
});
