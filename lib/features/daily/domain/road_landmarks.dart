import 'dart:convert';

import 'reading_plan.dart';

/// A Bible place or object that stands beside the road at the stop where its
/// passage is read (a garden at Genesis 1, a stable at Matthew 1). Pure data:
/// the picture is named by [art], never drawn here.
class Landmark {
  const Landmark({
    required this.id,
    required this.book,
    required this.fromChapter,
    required this.toChapter,
    required this.title,
    required this.short,
    required this.ref,
    required this.art,
  });

  final String id;

  /// USFM book code, e.g. `GEN`.
  final String book;
  final int fromChapter;
  final int toChapter;
  final String title;
  final String short;

  /// A reference line only ("Genesis 1:1"), never quoted text.
  final String ref;

  /// Sprite key, or null while that landmark has no art yet (it is then never
  /// placed on the road).
  final String? art;

  factory Landmark.fromJson(Map<String, dynamic> j) => Landmark(
        id: j['id'] as String,
        book: j['book'] as String,
        fromChapter: j['from'] as int,
        toChapter: j['to'] as int,
        title: j['title'] as String,
        short: j['short'] as String,
        ref: j['ref'] as String,
        art: j['art'] as String?,
      );
}

List<Landmark> parseLandmarks(String json) => [
      for (final m in jsonDecode(json) as List)
        Landmark.fromJson(m as Map<String, dynamic>),
    ];

/// Which landmark stands at which plan day (1-based day index).
///
/// A landmark is placed at the first day whose passages touch its chapters, so
/// it arrives the moment the reader reaches that part of the Bible. One
/// landmark per day: if two want the same day, the later one takes the next day
/// that touches it, and is dropped if there is none. Landmarks without art are
/// skipped.
Map<int, Landmark> landmarksByDay(ReadingPlan plan, List<Landmark> all) {
  final placed = <String>{};
  final out = <int, Landmark>{};
  for (final day in plan.days) {
    for (final lm in all) {
      if (lm.art == null || placed.contains(lm.id)) continue;
      final touches = day.passages.any((p) =>
          p.start.book == lm.book &&
          p.start.chapter <= lm.toChapter &&
          p.end.chapter >= lm.fromChapter);
      if (!touches) continue;
      out[day.dayIndex] = lm;
      placed.add(lm.id);
      break;
    }
  }
  return out;
}
