import 'reading_plan.dart';

/// The next day of a plan the reader has not finished.
///
/// Progress-driven, not calendar-driven. Day N of the plan is *not* "days since
/// you started"; it is the first day you have not read. Miss a week and you fall
/// behind schedule, but you never skip content -- and skipped content is what
/// makes someone abandon a Bible-in-a-year plan, because the plan has silently
/// decided they are simply not going to read Leviticus.
///
/// Returns null when every day is done, which is the moment to congratulate
/// rather than to open a passage that does not exist.
int? nextPlanDayIndex(Set<int> completedDayIndexes, int dayCount) {
  for (var day = 1; day <= dayCount; day++) {
    if (!completedDayIndexes.contains(day)) return day;
  }
  return null;
}

/// The reference to hand `openBibleLink` when opening [day].
///
/// **The start of the first passage, never the whole range.** This looks like a
/// pointless narrowing until you read `BibleLinkResolver.resolve`: it sets
/// `chapter = start.chapter` but `hiTo = range.end.verse`, and
/// [BibleNavigationTarget] has no end-chapter field at all. So handing it a real
/// plan day like `GEN.1.1-4.26` opens Genesis 1 and flashes "verses 1 to 26" --
/// of chapter 1. Not an error, not a crash: just a highlight that means nothing,
/// on most days of most plans.
///
/// Opening at the passage's first verse is honest about what the reader can do
/// today, and they page forward through the rest.
String openingRefFor(PlanDay day) => day.passages.first.start.toString();
