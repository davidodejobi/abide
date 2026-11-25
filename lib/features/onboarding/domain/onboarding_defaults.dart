import 'package:openbaptisthymnal/features/bible/model/bible_edition.dart';
import 'package:openbaptisthymnal/features/daily/domain/plan_schedule.dart';
import 'package:openbaptisthymnal/features/daily/domain/reading_plan.dart';

/// Pure choices behind the onboarding defaults, kept out of the UI so they can
/// be tested without a widget tree.

/// The plan pre-selected on the plan step. The New Testament in 90 days is the
/// one most people finish (see `kBundledPlanIds`).
const kOnboardingDefaultPlanId = 'nt-90';

/// The plan to pre-select: [kOnboardingDefaultPlanId], or the first open plan
/// if that one is not available. Never a plan still locked on [today].
ReadingPlan onboardingDefaultPlan(List<ReadingPlan> plans, DateTime today) {
  final open = [
    for (final p in plans)
      if (!PlanSchedule(p).isLocked(today)) p,
  ];
  return open.firstWhere((p) => p.id == kOnboardingDefaultPlanId,
      orElse: () => open.isEmpty ? plans.first : open.first);
}

/// Languages we ship a Bible edition for, first-seen order.
List<String> onboardingLanguages(
    [List<BibleEdition> editions = kBibleEditions]) {
  final seen = <String>[];
  for (final e in editions) {
    if (!seen.contains(e.languageCode)) seen.add(e.languageCode);
  }
  return seen;
}

/// The reading language to start on: the phone's language if we have a Bible
/// in it, otherwise English.
String defaultLanguageFor(String localeCode,
    [List<BibleEdition> editions = kBibleEditions]) {
  final code = localeCode.toLowerCase();
  return onboardingLanguages(editions).contains(code) ? code : 'en';
}

/// Editions offered for [languageCode], in catalogue order.
List<BibleEdition> editionsForLanguage(String languageCode,
    [List<BibleEdition> editions = kBibleEditions]) {
  return [
    for (final e in editions)
      if (e.languageCode == languageCode) e,
  ];
}

/// The edition to pre-select when the language changes.
String defaultEditionFor(String languageCode,
    [List<BibleEdition> editions = kBibleEditions]) {
  final list = editionsForLanguage(languageCode, editions);
  return (list.isEmpty ? editions.first : list.first).id;
}
