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

  Future<void> _decode(String n, {int? width}) => _loading[n] ??= () async {
        final data = await rootBundle.load('$_dir/$n.webp');
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
            targetWidth: width);
        _images[n] = (await codec.getNextFrame()).image;
      }();

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
