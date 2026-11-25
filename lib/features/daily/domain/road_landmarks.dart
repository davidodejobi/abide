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

  /// Sprite key, or null while that landmark has no art yet (it is then drawn
  /// as a small marker sign, so it can still be tapped).
  final String? art;

  /// The verse the reader opens at, as a link key (`GEN.1.1`), read off the
  /// last `chapter:verse` of [ref]; the first chapter, verse 1 if [ref] has none.
  String get openingKey {
    final m = RegExp(r'(\d+):(\d+)\s*$').firstMatch(ref);
    return m == null
        ? '$book.$fromChapter.1'
        : '$book.${m.group(1)}.${m.group(2)}';
  }

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

/// Which landmarks stand at which plan day (1-based day index), at most
/// [perDay] per day (they stand either side of the stop).
///
/// A landmark is placed at the first day whose passages touch its chapters, so
/// it arrives the moment the reader reaches that part of the Bible. A day's own
/// matches always win its slots. A landmark that does not fit moves to the next
/// day only if that day has a slot left after its own matches, and never
/// further. A landmark whose art was used within the last [artGapDays] days is
/// dropped so the road does not repeat itself. Landmarks without art are never
/// placed unless [placeArtless] is set (the road draws them as marker signs,
/// each its own "picture" for the repeat rule). Own matches come first in each
/// day's list, then any carried over from the day before.
Map<int, List<Landmark>> landmarksByDay(ReadingPlan plan, List<Landmark> all,
    {int artGapDays = 4, bool placeArtless = false, int perDay = 2}) {
  final placed = <String>{};
  final lastArtDay = <String, int>{};
  final out = <int, List<Landmark>>{};
  var displaced = <Landmark>[];
  for (final day in plan.days) {
    bool touches(Landmark lm) => day.passages.any((p) =>
        p.start.book == lm.book &&
        p.start.chapter <= lm.toChapter &&
        p.end.chapter >= lm.fromChapter);
    final own = [
      for (final lm in all)
        if ((placeArtless || lm.art != null) &&
            !placed.contains(lm.id) &&
            touches(lm))
          lm,
    ];
    final carried = [
      for (final lm in displaced)
        if (!placed.contains(lm.id) && !own.contains(lm)) lm,
    ];
    displaced = [];
    final today = <Landmark>[];
    void place(Landmark lm, bool canCarry) {
      final key = lm.art ?? lm.id;
      final last = lastArtDay[key];
      if (last != null && day.dayIndex - last < artGapDays) {
        placed.add(lm.id); // same picture as a recent stop: drop, don't retry
        return;
      }
      if (today.length >= perDay) {
        if (canCarry) displaced.add(lm);
        return;
      }
      today.add(lm);
      placed.add(lm.id);
      lastArtDay[key] = day.dayIndex;
    }

    for (final lm in own) {
      place(lm, true);
    }
    for (final lm in carried) {
      place(lm, false);
    }
    if (today.isNotEmpty) out[day.dayIndex] = today;
  }
  return out;
}
