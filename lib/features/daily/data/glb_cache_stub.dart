import 'dart:typed_data';

import '../domain/landmark_glb_loader.dart';

GlbCache? createGlbCache() => null;

/// No network from here on web: the sprite stands in for a missing model.
Future<Uint8List?> fetchGlb(Uri url) async => null;
