import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/landmark_glb_loader.dart';

GlbCache? createGlbCache() => _DiskGlbCache();

class _DiskGlbCache implements GlbCache {
  Future<Directory> _dir() async {
    final base = await getApplicationSupportDirectory();
    return Directory(p.join(base.path, 'landmarks')).create(recursive: true);
  }

  @override
  Future<Uint8List?> read(String name) async {
    final f = File(p.join((await _dir()).path, name));
    return await f.exists() ? f.readAsBytes() : null;
  }

  @override
  Future<void> write(String name, Uint8List bytes) async {
    final dir = (await _dir()).path;
    final tmp = File(p.join(dir, '$name.part'));
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp.rename(p.join(dir, name));
  }

  @override
  Future<bool> has(String name) async =>
      File(p.join((await _dir()).path, name)).exists();

  @override
  Future<void> delete(String name) async {
    final f = File(p.join((await _dir()).path, name));
    if (await f.exists()) await f.delete();
  }
}

/// GET [url]; the body, or null on any failure. Models are small (< 60 KB),
/// so a short timeout is enough.
Future<Uint8List?> fetchGlb(Uri url) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
  try {
    final res = await (await client.getUrl(url)).close()
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return null;
    final b = BytesBuilder(copy: false);
    await for (final c in res.timeout(const Duration(seconds: 15))) {
      b.add(c);
      if (b.length > 1024 * 1024) return null;
    }
    return b.takeBytes();
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
  }
}
