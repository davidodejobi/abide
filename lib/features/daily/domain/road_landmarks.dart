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
    this.opening,
  });

  /// One placement on the road, also the key of its story (`d001-garden`).
  final String id;

  /// USFM book code, e.g. `GEN`.
  final String book;
  final int fromChapter;
  final int toChapter;
  final String title;
  final String short;

  /// A reference line only ("Genesis 1:1 to 4:26"), never quoted text.
  final String ref;

  /// Sprite key, or null while that landmark has no art yet (it is then drawn
  /// as a small marker sign, so it can still be tapped).
  final String? art;

  /// The verse the reader opens at, as a link key (`GEN.1.1`); read off the
  /// last `chapter:verse` of [ref] when absent.
  final String? opening;

  String get openingKey {
    if (opening != null) return opening!;
    final m = RegExp(r'(\d+):(\d+)\s*$').firstMatch(ref);
    return m == null
        ? '$book.$fromChapter.1'
        : '$book.${m.group(1)}.${m.group(2)}';
  }
}

/// One of the 127 models: its sprite is `lm_<art>.webp`, its glb is
/// identified by [sha256] and is bundled with the app only when [bundled].
class LandmarkModelInfo {
  const LandmarkModelInfo({
    required this.art,
    required this.title,
    required this.sha256,
    required this.bundled,
    this.bytes = 0,
  });

  final String art;
  final String title;
  final String sha256;
  final bool bundled;

  /// Size of the glb in bytes, from the manifest.
  final int bytes;

  String get id => 'lm_$art';

  /// Name of the file on the CDN: `<id>-<first 8 of the hash>.glb`.
  String get remoteName => '$id-${sha256.substring(0, 8)}.glb';
}

/// One day of the catalog: which landmark(s) stand at it and the passages it
/// covers, as (book, first chapter, last chapter).
class CatalogDay {
  const CatalogDay({
    required this.day,
    required this.art,
    required this.story,
    required this.title,
    required this.ref,
    required this.spans,
    this.also,
    this.alsoStory,
  });

  final int day;
  final String art, story, title, ref;
  final String? also, alsoStory;
  final List<(String, int, int)> spans;

  bool covers(String book, int chapter) =>
      spans.any((s) => s.$1 == book && s.$2 <= chapter && chapter <= s.$3);
}

class LandmarkCatalog {
  const LandmarkCatalog(
      {required this.plan, required this.models, required this.days});

  /// The plan id the catalog's day numbers belong to.
  final String plan;
  final Map<String, LandmarkModelInfo> models;
  final List<CatalogDay> days;

  /// The catalog day that stands for [day] of [forPlan]: the same day number
  /// for the catalog's own plan, otherwise the catalog day whose passages hold
  /// the first chapter of the day's reading.
  CatalogDay? dayFor(ReadingPlan forPlan, PlanDay day) {
    if (forPlan.id == plan) {
      return day.dayIndex >= 1 && day.dayIndex <= days.length
          ? days[day.dayIndex - 1]
          : null;
    }
    if (day.passages.isEmpty) return null;
    final s = day.passages.first.start;
    for (final d in days) {
      if (d.covers(s.book, s.chapter)) return d;
    }
    return null;
  }

  List<Landmark> _landmarks(CatalogDay d) {
    final (book, from, to) = d.spans.first;
    Landmark make(String id, String art, String title) => Landmark(
          id: id,
          book: book,
          fromChapter: from,
          toChapter: to,
          title: title,
          short: models[art]?.title ?? title,
          ref: d.ref,
          art: art,
          opening: '$book.$from.1',
        );
    return [
      make(d.story, d.art, d.title),
      if (d.also != null)
        make(d.alsoStory!, d.also!, models[d.also]?.title ?? d.title),
    ];
  }
}

/// The models of the bundled `landmarks.json`, by art key.
Map<String, LandmarkModelInfo> parseLandmarkModels(String modelsJson) {
  final lm = (jsonDecode(modelsJson) as Map)['landmarks'] as Map;
  return {
    for (final e in lm.entries)
      e.key as String: LandmarkModelInfo(
        art: e.key as String,
        title: (e.value as Map)['title'] as String,
        sha256: (e.value as Map)['sha256'] as String,
        bundled: (e.value as Map)['bundled'] as bool,
        bytes: ((e.value as Map)['bytes'] as num?)?.toInt() ?? 0,
      ),
  };
}

/// Parses the bundled `landmarks.json` (models) and `landmark_days.json`.
LandmarkCatalog parseLandmarkCatalog(String modelsJson, String daysJson) {
  final d = jsonDecode(daysJson) as Map<String, dynamic>;
  return LandmarkCatalog(
    plan: d['plan'] as String,
    models: parseLandmarkModels(modelsJson),
    days: [
      for (final r in d['days'] as List)
        CatalogDay(
          day: r['day'] as int,
          art: r['landmark'] as String,
          story: r['story'] as String,
          title: r['title'] as String,
          ref: r['ref'] as String,
          spans: [
            for (final s in r['spans'] as List)
              (s[0] as String, s[1] as int, s[2] as int),
          ],
          also: r['also'] as String?,
          alsoStory: r['also_story'] as String?,
        ),
    ],
  );
}

/// Which landmarks stand at which plan day (1-based day index): the catalog's
/// landmark and optional second one for that day, at most two per day (they
/// stand either side of the stop).
///
/// A landmark is used on many days, so one whose art stood within the last
/// [artGapDays] days is skipped: the road never shows a landmark beside a copy
/// of itself. A skipped lead lets the day's second landmark take its slot. A
/// catalog day is shown once, so a short plan that covers several days of
/// reading in one stop does not repeat it. Pure and in day order.
Map<int, List<Landmark>> landmarksByDay(ReadingPlan plan, LandmarkCatalog cat,
    {int artGapDays = 4}) {
  final lastArtDay = <String, int>{};
  final shown = <String>{};
  final out = <int, List<Landmark>>{};
  for (final day in plan.days) {
    final cd = cat.dayFor(plan, day);
    if (cd == null || !shown.add(cd.story)) continue;
    final today = <Landmark>[];
    for (final lm in cat._landmarks(cd)) {
      final last = lastArtDay[lm.art];
      if (last != null && day.dayIndex - last < artGapDays) continue;
      today.add(lm);
    }
    for (final lm in today) {
      lastArtDay[lm.art!] = day.dayIndex;
    }
    if (today.isNotEmpty) out[day.dayIndex] = today;
  }
  return out;
}
