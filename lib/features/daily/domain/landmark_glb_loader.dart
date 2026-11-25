import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'road_landmarks.dart';

/// Where downloaded models are kept between runs, by file name. Null cache
/// (web, or no writable folder) means every tier below it still works.
abstract class GlbCache {
  Future<Uint8List?> read(String name);

  /// Must be atomic: a reader never sees half a file.
  Future<void> write(String name, Uint8List bytes);
}

/// Fetches [url]; null on any failure (offline, 404, timeout).
typedef GlbFetcher = Future<Uint8List?> Function(Uri url);

/// Loads the glb of one landmark, cheapest source first:
///
/// 1. the disk cache, keyed by id + hash (a new hash is a new name, so a
///    changed model is fetched again; a cached file whose hash is wrong is
///    ignored),
/// 2. the glb bundled in the app (only the models flagged `bundled`),
/// 3. the CDN at `<cdnBase>/landmarks/<id>-<hash8>.glb`, hash-checked, then
///    cached. Skipped entirely when [cdnBase] is empty.
///
/// Returns null when none works; the caller then keeps the flat sprite.
/// Never throws: a failing tier is just the next tier's turn.
class LandmarkGlbLoader {
  LandmarkGlbLoader({
    this.cache,
    required this.loadBundled,
    required this.fetch,
    this.cdnBase = const String.fromEnvironment('LANDMARK_CDN_BASE'),
  });

  final GlbCache? cache;
  final Future<Uint8List> Function(String art) loadBundled;
  final GlbFetcher fetch;
  final String cdnBase;

  static bool _matches(Uint8List b, String hash) =>
      sha256.convert(b).toString() == hash;

  Future<Uint8List?> load(LandmarkModelInfo m) async {
    final name = m.remoteName;
    try {
      final hit = await cache?.read(name);
      if (hit != null && _matches(hit, m.sha256)) return hit;
    } catch (_) {}
    if (m.bundled) {
      try {
        return await loadBundled(m.art);
      } catch (_) {}
    }
    if (cdnBase.isEmpty) return null;
    try {
      final base = cdnBase.endsWith('/')
          ? cdnBase.substring(0, cdnBase.length - 1)
          : cdnBase;
      final got = await fetch(Uri.parse('$base/landmarks/$name'));
      if (got == null || !_matches(got, m.sha256)) return null;
      try {
        await cache?.write(name, got);
      } catch (_) {}
      return got;
    } catch (_) {
      return null;
    }
  }
}
