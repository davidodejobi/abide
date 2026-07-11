import 'package:openbaptisthymnal/features/bible/domain/verse_ref.dart';

/// A reading plan: an ordered schedule of passages, one entry per day.
///
/// A plan is a *schedule of references*, never any Bible text. That is what
/// keeps it clear of copyright: a list of chapter references is fact, not
/// creative expression, and the words themselves come from the translations
/// already bundled with the app. Plans here are generated (see
/// `plan_generator.dart`), not transcribed from a published plan.
class ReadingPlan {
  const ReadingPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.days,
  });

  /// Stable slug, e.g. `bible-in-a-year`. Persisted, so it must not change.
  final String id;
  final String title;
  final String description;

  /// Day 1 first. Length is the plan's duration.
  final List<PlanDay> days;

  int get dayCount => days.length;

  /// The day at [dayIndex] (1-based), or null if it falls outside the plan --
  /// which happens the moment someone finishes a plan and keeps reading.
  PlanDay? dayAt(int dayIndex) {
    if (dayIndex < 1 || dayIndex > days.length) return null;
    return days[dayIndex - 1];
  }

  factory ReadingPlan.fromJson(Map<String, dynamic> json) {
    return ReadingPlan(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      days: (json['days'] as List)
          .map((d) => PlanDay.fromJson(d as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'days': days.map((d) => d.toJson()).toList(growable: false),
      };
}

/// One day's reading.
class PlanDay {
  const PlanDay({required this.dayIndex, required this.passages});

  /// **1-based.** Day 1 is the first day of the plan. This number is half of
  /// the `<planId>:<dayIndex>` progress key, so an off-by-one here does not
  /// crash -- it silently marks the wrong day read.
  final int dayIndex;

  /// The passages to read, in order.
  ///
  /// A list rather than a single range because [VerseRange] cannot cross a book
  /// boundary, so a day that runs from the end of one book into the next is
  /// necessarily two ranges (`MAL.4.1-6`, `MAT.1.1-25`).
  final List<VerseRange> passages;

  factory PlanDay.fromJson(Map<String, dynamic> json) {
    final raw = (json['passages'] as List).cast<String>();
    final passages = <VerseRange>[];
    for (final ref in raw) {
      final range = VerseRange.tryParse(ref);
      if (range == null) {
        throw FormatException('plan day ${json['day']}: bad passage "$ref"');
      }
      passages.add(range);
    }
    return PlanDay(
      dayIndex: json['day'] as int,
      passages: List.unmodifiable(passages),
    );
  }

  Map<String, dynamic> toJson() => {
        'day': dayIndex,
        'passages': passages.map((p) => p.toString()).toList(growable: false),
      };
}
