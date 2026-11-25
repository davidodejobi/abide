import 'dart:convert';

import 'reading_plan.dart';
import 'road_landmarks.dart';

/// How much a chapter has to show on the road. Major chapters carry a
/// landmark, minor ones a small prop, scenic ones only scenery.
enum AtlasTier { scenic, minor, major }

/// One Bible chapter's road content. Pure data, no art.
class AtlasChapter {
  const AtlasChapter({
    required this.book,
    required this.chapter,
    required this.regionKey,
    required this.region,
    required this.biome,
    required this.tier,
    this.prop,
    this.landmark,
    this.event,
  });

  final String book;
  final int chapter;

  /// Identity used to spot a border crossing. Equals the display [region] for
  /// atlas chapters; `book:GEN` for a chapter the atlas does not know.
  final String regionKey;

  /// Display name, or null for a chapter the atlas does not know (the caller
  /// shows the book name instead).
  final String? region;
  final String biome;
  final AtlasTier tier;
  final String? prop;
  final String? landmark;
  final String? event;

  /// What a chapter missing from the atlas gets, so any plan still has a road.
  factory AtlasChapter.fallback(String book, int chapter) => AtlasChapter(
        book: book,
        chapter: chapter,
        regionKey: 'book:$book',
        region: null,
        biome: 'road',
        tier: AtlasTier.scenic,
      );
}

/// The Bible-wide chapter map (`assets/images/road/road_atlas.json`): every
/// chapter to region, biome, tier and prop, so any plan, including one sent by
/// the server, gets road content without plan-specific art.
class RoadAtlas {
  RoadAtlas._(this._chapters);

  final Map<String, AtlasChapter> _chapters;

  int get length => _chapters.length;

  /// Parses the compact file: `{regions: [name], chapters: [[key, regionIdx,
  /// biome, tier j/n/s, prop, landmark, event]]}` (empty string = none).
  factory RoadAtlas.parse(String json) {
    final j = jsonDecode(json) as Map<String, dynamic>;
    final regions = (j['regions'] as List).cast<String>();
    final out = <String, AtlasChapter>{};
    for (final r in j['chapters'] as List) {
      final row = r as List;
      final key = row[0] as String;
      final dot = key.indexOf('.');
      final region = regions[row[1] as int];
      out[key] = AtlasChapter(
        book: key.substring(0, dot),
        chapter: int.parse(key.substring(dot + 1)),
        regionKey: region,
        region: region,
        biome: row[2] as String,
        tier: switch (row[3] as String) {
          'j' => AtlasTier.major,
          'n' => AtlasTier.minor,
          _ => AtlasTier.scenic,
        },
        prop: row[4] == '' ? null : row[4] as String,
        landmark: row[5] == '' ? null : row[5] as String,
        event: row[6] == '' ? null : row[6] as String,
      );
    }
    return RoadAtlas._(out);
  }

  /// The chapter, or a scenic fallback when the atlas lacks it.
  AtlasChapter chapter(String book, int chapter) =>
      _chapters['$book.$chapter'] ?? AtlasChapter.fallback(book, chapter);

  bool has(String book, int chapter) => _chapters.containsKey('$book.$chapter');
}

/// What the road shows at one plan day.
class DayContent {
  const DayContent({
    required this.chapters,
    required this.biome,
    required this.tier,
    required this.props,
    required this.gateway,
  });

  /// Every chapter of the day, in reading order.
  final List<AtlasChapter> chapters;

  /// Set by the first chapter, so scenery only changes at a day boundary.
  final String biome;

  /// The day's tier after landmark placement: [AtlasTier.major] only when a
  /// landmark really stands here, otherwise a major chapter reads as scenic.
  final AtlasTier tier;

  /// Up to two prop ids for the sides of the road (empty unless minor).
  final List<String> props;

  /// True when the first chapter's region differs from the previous day's.
  final bool gateway;

  /// The first chapter's region name, null when the atlas lacks it.
  String? get region => chapters.first.region;
}

/// Resolves every day of [plan] against [atlas]. [landmarks] is the result of
/// `landmarksByDay`: it decides which days really show a landmark, the atlas
/// only supplies the minor props, biome and regions. Works for any plan.
Map<int, DayContent> resolveDays(
    ReadingPlan plan, RoadAtlas atlas, Map<int, List<Landmark>> landmarks) {
  final out = <int, DayContent>{};
  String? prevRegion;
  String? prevProp;
  for (final day in plan.days) {
    final chapters = <AtlasChapter>[
      for (final p in day.passages)
        for (var c = p.start.chapter; c <= p.end.chapter; c++)
          atlas.chapter(p.start.book, c),
    ];
    if (chapters.isEmpty) continue;
    var tier = AtlasTier.scenic;
    for (final c in chapters) {
      if (c.tier == AtlasTier.minor) tier = AtlasTier.minor;
    }
    if (landmarks[day.dayIndex]?.isNotEmpty == true) tier = AtlasTier.major;

    final props = <String>[];
    if (tier == AtlasTier.minor) {
      final all = [
        for (final c in chapters)
          if (c.tier == AtlasTier.minor && c.prop != null) c.prop!,
      ];
      // Never the same prop on two days running: step to the next minor one.
      final pick = all.where((p) => p != prevProp).toList();
      if (pick.isNotEmpty) props.add(pick.first);
      if (pick.length > 1) props.add(pick[1]);
    }
    prevProp = props.isEmpty ? null : props.first;

    final first = chapters.first;
    out[day.dayIndex] = DayContent(
      chapters: chapters,
      biome: first.biome,
      tier: tier,
      props: props,
      gateway: prevRegion != null && prevRegion != first.regionKey,
    );
    prevRegion = first.regionKey;
  }
  return out;
}
