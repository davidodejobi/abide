import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../../domain/road_landmarks.dart';

/// The road's Blender-rendered sprites and the landmark list, decoded once and
/// shared by every Today tab mount (about 6 MB of pixels, never re-decoded).
class RoadArt {
  RoadArt._(this._images, this.landmarks);

  final Map<String, ui.Image> _images;
  final List<Landmark> landmarks;

  ui.Image? operator [](String name) => _images[name];

  static const _dir = 'assets/images/road/living';
  static const names = [
    'stop_done', 'stop_cur', 'stop_lock', 'trav', 'hills', 'cloud',
    'prop_tree', 'prop_cypress', 'prop_bush', 'prop_pond', 'prop_flowers',
    'prop_rock', //
    'lm_garden', 'lm_ark', 'lm_manger', 'lm_cross', 'lm_tomb', 'lm_sinai',
  ];

  static Future<RoadArt>? _memo;

  static Future<RoadArt> load() => _memo ??= _load();

  static Future<RoadArt> _load() async {
    final images = <String, ui.Image>{};
    await Future.wait([
      for (final n in names)
        () async {
          final data = await rootBundle.load('$_dir/$n.webp');
          final codec =
              await ui.instantiateImageCodec(data.buffer.asUint8List());
          images[n] = (await codec.getNextFrame()).image;
        }(),
    ]);
    final landmarks = parseLandmarks(
        await rootBundle.loadString('assets/images/road/landmarks.json'));
    return RoadArt._(images, landmarks);
  }
}
