import 'reading_plan.dart';

/// Whole chapters in one plan day.
int chaptersInDay(PlanDay day) => day.passages
    .fold<int>(0, (n, p) => n + (p.end.chapter - p.start.chapter + 1));

/// Average chapters per day over the whole plan, rounded, never below 1.
int averageChaptersPerDay(ReadingPlan plan) {
  if (plan.days.isEmpty) return 1;
  final total = plan.days.fold<int>(0, (n, d) => n + chaptersInDay(d));
  final avg = (total / plan.days.length).round();
  return avg < 1 ? 1 : avg;
}

/// The last day of a plan started on [start] and read one day at a time.
DateTime planFinishDate(DateTime start, int dayCount) => DateTime(
    start.year, start.month, start.day + (dayCount < 1 ? 0 : dayCount - 1));
