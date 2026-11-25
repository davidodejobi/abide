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
/// landmark per day: a landmark that loses its day to an earlier one moves to
/// the next day if that day is free (the tomb follows the cross), and is
/// dropped otherwise. A landmark whose art was used within the last
/// [artGapDays] days is skipped so the road does not repeat itself. Landmarks
/// without art are never placed.
Map<int, Landmark> landmarksByDay(ReadingPlan plan, List<Landmark> all,
    {int artGapDays = 4}) {
  final placed = <String>{};
  final lastArtDay = <String, int>{};
  final out = <int, Landmark>{};
  var displaced = <Landmark>[];
  for (final day in plan.days) {
    bool touches(Landmark lm) => day.passages.any((p) =>
        p.start.book == lm.book &&
        p.start.chapter <= lm.toChapter &&
        p.end.chapter >= lm.fromChapter);
    final candidates = [
      ...displaced,
      for (final lm in all)
        if (lm.art != null && !displaced.contains(lm) && touches(lm)) lm,
    ];
    displaced = [];
    for (final lm in candidates) {
      if (placed.contains(lm.id)) continue;
      final last = lastArtDay[lm.art];
      if (last != null && day.dayIndex - last < artGapDays) {
        placed.add(lm.id); // same picture as a recent stop: drop, don't retry
        continue;
      }
      if (out.containsKey(day.dayIndex)) {
        if (touches(lm) && !displaced.contains(lm)) displaced.add(lm);
        continue;
      }
      out[day.dayIndex] = lm;
      placed.add(lm.id);
      lastArtDay[lm.art!] = day.dayIndex;
    }
  }
  return out;
}
