import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/daily/domain/landmark_glb_loader.dart';
import 'package:openbaptisthymnal/features/daily/domain/road_landmarks.dart';

class _MemCache implements GlbCache {
  final files = <String, Uint8List>{};
  @override
  Future<Uint8List?> read(String name) async => files[name];
  @override
  Future<void> write(String name, Uint8List bytes) async => files[name] = bytes;
}

void main() {
  final glb = Uint8List.fromList(List.generate(64, (i) => i));
  final hash = sha256.convert(glb).toString();
  LandmarkModelInfo info({bool bundled = false, String? sha}) =>
      LandmarkModelInfo(
          art: 'well', title: 'Well', sha256: sha ?? hash, bundled: bundled);

  late List<String> calls;
  late _MemCache cache;

  LandmarkGlbLoader loader({
    String cdn = 'https://cdn.test',
    Uint8List? remote,
    bool bundledOk = true,
    bool withCache = true,
  }) =>
      LandmarkGlbLoader(
        cache: withCache ? cache : null,
        cdnBase: cdn,
        loadBundled: (art) async {
          calls.add('bundled');
          if (!bundledOk) throw StateError('no asset');
          return glb;
        },
        fetch: (url) async {
          calls.add('fetch $url');
          return remote;
        },
      );

  setUp(() {
    calls = [];
    cache = _MemCache();
  });

  test('remote name is id plus the first 8 hash characters', () {
    expect(info().remoteName, 'lm_well-${hash.substring(0, 8)}.glb');
  });

  test('the cache wins over everything, with no bundle or network touched',
      () async {
    cache.files[info().remoteName] = glb;
    expect(await loader(remote: glb).load(info(bundled: true)), glb);
    expect(calls, isEmpty);
  });

  test('a cached file with the wrong hash is ignored, and the bundle is used',
      () async {
    cache.files[info().remoteName] = Uint8List.fromList([1, 2, 3]);
    expect(await loader().load(info(bundled: true)), glb);
    expect(calls, ['bundled']);
  });

  test('a changed hash is a different cache name, so it is fetched again',
      () async {
    final old = info();
    cache.files[old.remoteName] = Uint8List.fromList([9, 9]);
    final next = Uint8List.fromList([5, 5, 5]);
    final fresh = info(sha: sha256.convert(next).toString());
    expect(await loader(remote: next).load(fresh), next);
    expect(calls.single, startsWith('fetch https://cdn.test/landmarks/lm_well-'));
    expect(cache.files[fresh.remoteName], next);
  });

  test('bundled models come from the bundle without the network', () async {
    expect(await loader(remote: glb).load(info(bundled: true)), glb);
    expect(calls, ['bundled']);
  });

  test('a model that is not bundled is fetched, verified and cached', () async {
    expect(await loader(remote: glb).load(info()), glb);
    expect(calls, [
      'fetch https://cdn.test/landmarks/${info().remoteName}',
    ]);
    expect(cache.files[info().remoteName], glb);
  });

  test('a download with the wrong hash is rejected and never cached', () async {
    final bad = Uint8List.fromList([0, 0, 0]);
    expect(await loader(remote: bad).load(info()), isNull);
    expect(cache.files, isEmpty);
  });

  test('an empty CDN define skips the network entirely', () async {
    expect(await loader(cdn: '', remote: glb).load(info()), isNull);
    expect(calls, isEmpty);
  });

  test('offline, or a missing bundled asset, falls through to null', () async {
    expect(await loader(remote: null).load(info()), isNull);
    expect(await loader(bundledOk: false).load(info(bundled: true)), isNull);
  });

  test('no cache (web) still loads from the bundle and the network', () async {
    expect(await loader(withCache: false, remote: glb).load(info()), glb);
  });

  test('a trailing slash on the base does not double up', () async {
    await loader(cdn: 'https://cdn.test/', remote: glb).load(info());
    expect(calls.single, startsWith('fetch https://cdn.test/landmarks/'));
  });
}
