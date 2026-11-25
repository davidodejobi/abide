import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart';

import '../../domain/reading_plan.dart';
import '../../domain/road_atlas.dart';
import '../../domain/road_landmarks.dart';

/// The road's Blender-rendered sprites and the landmark list, decoded once and
/// shared by every Today tab mount. The core sprites (stops, traveller,
/// scenery) load together; a landmark sprite is decoded only when the active
/// plan has a stop for it ([ensureLandmarks]), so art that can never appear is
/// never held in memory.
class RoadArt {
  RoadArt._(this._images, this.landmarks);

  final Map<String, ui.Image> _images;
  final List<Landmark> landmarks;
  final _loading = <String, Future<void>>{};

  ui.Image? operator [](String name) => _images[name];

  static const _dir = 'assets/images/road/living';
  static const names = [
    'stop_done',
    'stop_cur',
    'stop_lock',
    'trav',
    'hills',
    'cloud',
    'prop_tree',
    'prop_cypress',
    'prop_bush',
    'prop_pond',
    'prop_flowers',
    'prop_rock',
  ];

  static Future<RoadArt>? _memo;

  static Future<RoadArt> load() => _memo ??= _load();

  static Future<RoadArt> _load() async {
    final art = RoadArt._(
        <String, ui.Image>{},
        parseLandmarks(
            await rootBundle.loadString('assets/images/road/landmarks.json')));
    await Future.wait([for (final n in names) art._decode(n)]);
    return art;
  }

  Future<void> _decode(String n, {int? width}) => _loading[n] ??= () async {
        final data = await rootBundle.load('$_dir/$n.webp');
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
            targetWidth: width);
        _images[n] = (await codec.getNextFrame()).image;
      }();

  /// A landmark's 4x4 turntable sheet, decoded at full size for one showcase.
  /// The caller owns the image and disposes it when the sheet closes.
  static Future<ui.Image> loadSpin(String art) async {
    final data = await rootBundle.load('$_dir/lm_${art}_spin.webp');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  /// Art keys whose sprite is missing or failed to decode; the road draws a
  /// signpost for those landmarks instead.
  final failed = <String>{};
  Set<String> _wanted = {};

  /// Landmark sprites are decoded at this width: they are drawn about 100
  /// design px wide, so this is sharp at 3x and a fifth of full size in memory.
  static const spriteWidth = 320;

  /// Makes [arts] (e.g. `garden`) the loaded landmark sprites: decodes the
  /// missing ones and evicts every other. A missing or broken sprite is
  /// recorded in [failed], never thrown.
  Future<void> ensureLandmarks(Iterable<String?> arts) {
    _wanted = {
      for (final a in arts)
        if (a != null) a,
    };
    for (final k in [
      for (final k in {..._images.keys, ..._loading.keys})
        if (k.startsWith('lm_') && !_wanted.contains(k.substring(3))) k,
    ]) {
      _images.remove(k)?.dispose();
      _loading.remove(k);
    }
    return Future.wait([
      for (final a in _wanted)
        _decode('lm_$a', width: spriteWidth).then((_) {
          // Evicted while decoding: do not keep it.
          if (!_wanted.contains(a)) {
            _images.remove('lm_$a')?.dispose();
            _loading.remove('lm_$a');
          }
        }, onError: (Object _) {
          failed.add(a);
        }),
    ]);
  }
}

Future<RoadAtlas>? _atlasMemo;

/// The bundled chapter atlas, parsed once and shared. A failed load is not
/// kept, so a later mount can retry.
Future<RoadAtlas> loadRoadAtlas() => _atlasMemo ??= rootBundle
        .loadString('assets/images/road/road_atlas.json')
        .then((s) => compute(RoadAtlas.parse, s))
        .catchError((Object e) {
      _atlasMemo = null;
      throw e;
    });

ReadingPlan? _resolvedPlan;
Map<int, DayContent> _resolvedDays = const {};

/// Resolves [plan] against [atlas], remembering the last result so the scene
/// and the day sheet share one resolution instead of each computing it.
Map<int, DayContent> resolvedDaysFor(
    ReadingPlan plan, RoadAtlas atlas, Map<int, List<Landmark>> landmarks) {
  if (!identical(_resolvedPlan, plan)) {
    _resolvedDays = resolveDays(plan, atlas, landmarks);
    _resolvedPlan = plan;
  }
  return _resolvedDays;
}

/// What the road shows at [dayIndex] of [plan] (region, chapters), or null if
/// the art or atlas cannot load. Reuses the scene's resolution when it has one.
Future<DayContent?> roadDayContent(ReadingPlan plan, int dayIndex) async {
  try {
    final art = await RoadArt.load();
    final atlas = await loadRoadAtlas();
    final lms = identical(_resolvedPlan, plan)
        ? const <int, List<Landmark>>{}
        : landmarksByDay(plan, art.landmarks, placeArtless: true);
    return resolvedDaysFor(plan, atlas, lms)[dayIndex];
  } catch (_) {
    return null;
  }
}
