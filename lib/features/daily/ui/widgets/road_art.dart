import 'dart:ui' as ui;

import 'package:flutter/services.dart';

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

  Future<void> _decode(String n) => _loading[n] ??= () async {
        final data = await rootBundle.load('$_dir/$n.webp');
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        _images[n] = (await codec.getNextFrame()).image;
      }();

  /// Art keys whose sprite is missing or failed to decode; the road draws a
  /// marker sign for those landmarks instead.
  final failed = <String>{};

  /// Decodes the sprites for the given landmark art keys (e.g. `garden`). A
  /// missing sprite is recorded in [failed], never thrown.
  Future<void> ensureLandmarks(Iterable<String?> arts) => Future.wait([
        for (final a in arts.toSet())
          if (a != null)
            _decode('lm_$a').catchError((Object _) {
              failed.add(a);
            }),
      ]);
}
