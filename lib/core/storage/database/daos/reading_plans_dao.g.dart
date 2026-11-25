// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_plans_dao.dart';

// ignore_for_file: type=lint
mixin _$ReadingPlansDaoMixin on DatabaseAccessor<AppDatabase> {
  $ReadingDaysTable get readingDays => attachedDatabase.readingDays;
  $PlanSubscriptionsTable get planSubscriptions =>
      attachedDatabase.planSubscriptions;
  $PlanDayProgressTable get planDayProgress => attachedDatabase.planDayProgress;
  ReadingPlansDaoManager get managers => ReadingPlansDaoManager(this);
}

class ReadingPlansDaoManager {
  final _$ReadingPlansDaoMixin _db;
  ReadingPlansDaoManager(this._db);
  $$ReadingDaysTableTableManager get readingDays =>
      $$ReadingDaysTableTableManager(_db.attachedDatabase, _db.readingDays);
  $$PlanSubscriptionsTableTableManager get planSubscriptions =>
      $$PlanSubscriptionsTableTableManager(
          _db.attachedDatabase, _db.planSubscriptions);
  $$PlanDayProgressTableTableManager get planDayProgress =>
      $$PlanDayProgressTableTableManager(
          _db.attachedDatabase, _db.planDayProgress);
}
