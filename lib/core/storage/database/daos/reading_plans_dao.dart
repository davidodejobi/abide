import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'reading_plans_dao.g.dart';

/// Persistence for the daily habit loop: which days were completed, which plan
/// the user follows, and how far through it they are.
///
/// Everything here is edition-independent. Progress is keyed on a plan's day
/// index and on calendar days, never on a Bible translation, so a reader who
/// switches from KJV to Yoruba keeps their streak and their place.
@DriftAccessor(tables: [ReadingDays, PlanSubscriptions, PlanDayProgress])
class ReadingPlansDao extends DatabaseAccessor<AppDatabase>
    with _$ReadingPlansDaoMixin {
  ReadingPlansDao(super.db);

  /// Deterministic row id, so re-marking a plan day updates in place instead of
  /// accumulating duplicates.
  String _progressId(String planId, int dayIndex) => '$planId:$dayIndex';

  // --- Streak ---------------------------------------------------------------

  /// Every completed day, as `YYYY-MM-DD` keys. The streak is computed from
  /// this set (see `features/daily/domain/streak.dart`); it is never stored.
  Stream<Set<String>> watchCompletedDayKeys() {
    return select(readingDays)
        .map((row) => row.dateKey)
        .watch()
        .map((keys) => keys.toSet());
  }

  Future<Set<String>> completedDayKeys() async {
    final rows = await select(readingDays).get();
    return {for (final row in rows) row.dateKey};
  }

  /// Marks [dateKey] complete. Idempotent: [ReadingDays.dateKey] is the primary
  /// key, so marking the same day twice cannot create a second row.
  ///
  /// A repeat overwrites rather than throwing, so the last [source] to claim the
  /// day wins. That only decides which label a day carries when it was earned
  /// twice over (read the plan, then also a loose chapter) -- the streak counts
  /// days, not sources, so it is unaffected either way.
  Future<void> markDayComplete({
    required String dateKey,
    required String source,
    required DateTime completedAt,
  }) {
    return into(readingDays).insertOnConflictUpdate(
      ReadingDaysCompanion.insert(
        dateKey: dateKey,
        source: source,
        completedAt: completedAt,
      ),
    );
  }

  /// Undoes a completed day. Needed because "Mark as read" is a tap, and taps
  /// are mis-hit -- a streak the user cannot correct is a streak they stop
  /// trusting.
  Future<void> unmarkDay(String dateKey) {
    return (delete(readingDays)..where((t) => t.dateKey.equals(dateKey))).go();
  }

  // --- Plan subscription ----------------------------------------------------

  /// The plan the user is currently following, if any.
  Stream<PlanSubscription?> watchActivePlan() {
    return (select(planSubscriptions)..where((t) => t.isActive.equals(true)))
        .watchSingleOrNull();
  }

  Future<PlanSubscription?> activePlan() {
    return (select(planSubscriptions)..where((t) => t.isActive.equals(true)))
        .getSingleOrNull();
  }

  /// Starts [planId] on [startDateKey] and makes it the only active plan.
  ///
  /// Deactivating the others first is what keeps [watchActivePlan]'s
  /// `watchSingleOrNull` honest: two active rows would make it throw, not
  /// return the newer one. Wrapped in a transaction so it can never be
  /// half-applied and leave the user with no active plan.
  Future<void> startPlan({
    required String planId,
    required String startDateKey,
  }) {
    return transaction(() async {
      await (update(planSubscriptions)..where((t) => t.isActive.equals(true)))
          .write(const PlanSubscriptionsCompanion(isActive: Value(false)));

      await into(planSubscriptions).insertOnConflictUpdate(
        PlanSubscriptionsCompanion.insert(
          planId: planId,
          startDateKey: startDateKey,
          isActive: const Value(true),
        ),
      );
    });
  }

  // No deactivateAllPlans() here yet. Settings will want "stop my plan", but
  // nothing calls it today, and an untested method that ships ahead of its
  // caller is just a code path nobody has run. It is four lines; it comes back
  // with its test when the UI needs it.

  // --- Plan progress --------------------------------------------------------

  /// The plan days completed for [planId], as 1-based day indexes.
  Stream<Set<int>> watchCompletedDayIndexes(String planId) {
    return (select(planDayProgress)..where((t) => t.planId.equals(planId)))
        .map((row) => row.dayIndex)
        .watch()
        .map((indexes) => indexes.toSet());
  }

  /// Marks day [dayIndex] of [planId] read. Idempotent via the deterministic id.
  Future<void> markPlanDayComplete({
    required String planId,
    required int dayIndex,
    required DateTime completedAt,
  }) {
    return into(planDayProgress).insertOnConflictUpdate(
      PlanDayProgressCompanion.insert(
        id: _progressId(planId, dayIndex),
        planId: planId,
        dayIndex: dayIndex,
        completedAt: completedAt,
      ),
    );
  }

  Future<void> unmarkPlanDay({
    required String planId,
    required int dayIndex,
  }) {
    return (delete(planDayProgress)
          ..where((t) => t.id.equals(_progressId(planId, dayIndex))))
        .go();
  }

  /// Wipes a plan's progress, for "start this plan over".
  Future<void> clearPlanProgress(String planId) {
    return (delete(planDayProgress)..where((t) => t.planId.equals(planId)))
        .go();
  }
}
