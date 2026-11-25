import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/notifications/notification_service.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/features/settings/providers/reading_reminder_provider.dart';
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

/// The subscription row for one plan, active or not (null if never joined).
final planSubscriptionProvider =
    StreamProvider.family<PlanSubscription?, String>((ref, planId) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.planSubscriptions)..where((t) => t.planId.equals(planId)))
      .watchSingleOrNull();
});

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

/// Today as a local-midnight date, from the injected clock. Deliberately does
/// not watch [todayKeyProvider]: that one owns a midnight timer, which screens
/// that only need the date (onboarding) should not start. Auto-disposed so a
/// sheet opened tomorrow reads tomorrow; providers that stay mounted across
/// midnight watch [todayKeyProvider] themselves.
final planTodayProvider = Provider.autoDispose<DateTime>((ref) {
  final now = ref.watch(dayPartClockProvider)();
  return DateTime(now.year, now.month, now.day);
});

/// Plans the user asked to be reminded about, by plan id. Drives the Today
/// countdown card, and for a fixed-start plan also schedules a one-off
/// notification for 08:00 local on its opening day.
final planRemindersProvider =
    NotifierProvider<PlanRemindersNotifier, Set<String>>(
        PlanRemindersNotifier.new);

class PlanRemindersNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => ref.watch(storageServiceProvider).getPlanReminders();

  /// Returns false when the notification could not be set up (permission
  /// refused or scheduling failed); the reminder is then left off.
  Future<bool> toggle(String planId, bool on) async {
    _set(planId, on);
    if (!on) {
      try {
        await ref
            .read(notificationServiceProvider)
            .cancel(NotificationIds.forPlan(planId));
      } catch (_) {}
      return true;
    }
    final ok = await _schedulePlanStart(ref, planId, ask: true);
    if (!ok) _set(planId, false);
    return ok;
  }

  void _set(String planId, bool on) {
    state = on ? {...state, planId} : ({...state}..remove(planId));
    ref.read(storageServiceProvider).savePlanReminders(state);
  }
}

/// One-off "starts today" notification at 08:00 local on the plan's opening
/// day. A plan with no fixed start, or a start already passed, needs none and
/// counts as success. With [ask] false permission is never requested: an
/// ungranted permission just skips quietly (startup reschedule).
Future<bool> _schedulePlanStart(Ref ref, String planId,
    {required bool ask}) async {
  try {
    final service = ref.read(notificationServiceProvider);
    final plans = await ref.read(availablePlansProvider.future);
    final plan = plans.where((p) => p.id == planId).firstOrNull;
    final opens = plan == null ? null : PlanSchedule(plan).opensOn;
    if (plan == null || opens == null) return true;
    final at = DateTime(opens.year, opens.month, opens.day, 8);
    if (!at.isAfter(ref.read(dayPartClockProvider)())) return true;
    final granted =
        ask ? await service.requestPermission() : await service.hasPermission();
    if (!granted) return !ask;
    await service.scheduleOnce(
      id: NotificationIds.forPlan(planId),
      at: at,
      title: '${plan.title} starts today',
      body: 'Day 1 is ready when you are.',
    );
    return true;
  } catch (_) {
    return false;
  }
}

/// Re-registers saved reminders after launch (the OS can drop them after a
/// reinstall or restore). Never prompts: does nothing unless permission is
/// already granted. Call after the first frame.
final rescheduleRemindersProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    try {
      final service = ref.read(notificationServiceProvider);
      if (!await service.hasPermission()) return;
      final storage = ref.read(storageServiceProvider);
      final minutes = storage.getReadingReminderMinutes();
      if (minutes != null) {
        await service.scheduleDaily(
          id: NotificationIds.dailyReading,
          hour: minutes ~/ 60,
          minute: minutes % 60,
          title: ReadingReminderNotifier.title,
          body: ReadingReminderNotifier.body,
        );
      }
      for (final id in storage.getPlanReminders()) {
        await _schedulePlanStart(ref, id, ask: false);
      }
    } catch (e) {
      debugPrint('Reminder reschedule failed: $e');
    }
  };
});

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
  final schedule = PlanSchedule(plan);
  // Only a calendar-anchored plan changes with the day, so only it follows the
  // midnight roll; a progress-driven one must not reload at midnight.
  final fallbackToday = ref.watch(planTodayProvider);
  final DateTime today = schedule.isFixed
      ? (dateFromKey(ref.watch(todayKeyProvider)) ?? fallbackToday)
      : fallbackToday;
  final run = schedule.runFor(subscription.startDateKey, today);
  // A fixed-start run from a past year is history, not today's plan: show the
  // picker so they can join this year's. Its progress stays where it is.
  if (!run.joined) return null;

  final done = await ref.watch(planProgressProvider(run.progressId).future);

  if (!run.anchored) {
    final next = nextPlanDayIndex(done, plan.dayCount);
    return TodaysReading(
      plan: plan,
      day: next == null ? null : plan.dayAt(next),
      completedDays: done.length,
      progressId: run.progressId,
    );
  }

  // Anchored: today's reading is the calendar day for everyone. Unread days
  // before it are an optional catch-up list, never "done".
  final c = run.calendarDay;
  final todayRead = done.contains(c);
  final finished = done.length >= plan.dayCount;
  return TodaysReading(
    plan: plan,
    day: finished
        ? null
        : plan.dayAt(!todayRead ? c : (c < plan.dayCount ? c + 1 : c)),
    completedDays: done.length,
    catchUpDays: schedule.catchUpCount(done, today),
    progressId: run.progressId,
    statuses: PlanDayStatuses(done: done, today: c),
  );
});

/// What the "Today's reading" card renders.
class TodaysReading {
  const TodaysReading({
    required this.plan,
    required this.day,
    required this.completedDays,
    this.catchUpDays = 0,
    this.progressId,
    this.statuses,
  });

  final ReadingPlan plan;

  /// The day to read next, or null when the plan is finished. On an anchored
  /// plan: today's calendar day, or tomorrow's once today is read.
  final PlanDay? day;

  final int completedDays;

  /// Unread days before today's calendar day on a fixed-start plan. Offered as
  /// catch-up, never as missed.
  final int catchUpDays;

  /// Where this run's progress is stored; the plan id for ordinary plans.
  final String? progressId;
  String get progressKey => progressId ?? plan.id;

  /// Set for anchored plans only; the one status source for road and sheets.
  final PlanDayStatuses? statuses;
  bool get isAnchored => statuses != null;

  /// Anchored: today's calendar day has been read.
  bool get todayRead =>
      statuses != null && statuses!.done.contains(statuses!.today);

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
    final db = ref.read(appDatabaseProvider);
    final existing = await (db.select(db.planSubscriptions)
          ..where((t) => t.planId.equals(plan.id)))
        .getSingleOrNull();

    // Someone who was already on the plan keeps it (their join date and their
    // progress), locked or not.
    final legacy = existing != null && schedule.isLegacy(existing.startDateKey);
    if (schedule.isLocked(today) && !legacy) return;

    // Re-picking inside the same run keeps the original join day. A new year
    // gets a new join day and a new progress bucket; nothing is deleted.
    final keep = existing != null &&
        (!schedule.isFixed ||
            legacy ||
            schedule.isCurrentRun(existing.startDateKey, today));
    await ref.read(readingPlansDaoProvider).startPlan(
          planId: plan.id,
          startDateKey: keep ? existing.startDateKey : dayKey(today),
        );
  };
});
