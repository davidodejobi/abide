import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:openbaptisthymnal/features/bible/data/sources/local/installed_bible_store.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_catalog.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_edition.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// `<app support>/bibles/<id>/{edition.json,manifest.json,books/*.json}`.
Future<InstalledBibleStore> createInstalledBibleStore() async {
  final support = await getApplicationSupportDirectory();
  return FileInstalledBibleStore(Directory(p.join(support.path, 'bibles')));
}

class FileInstalledBibleStore implements InstalledBibleStore {
  FileInstalledBibleStore(this.root);

  final Directory root;

  Directory _dir(String id) => Directory(p.join(root.path, id));

  @override
  Future<List<BibleEdition>> list() async {
    if (!await root.exists()) return const [];
    final out = <BibleEdition>[];
    await for (final e in root.list()) {
      // `.tmp-*` folders are unfinished installs; they have no edition.json
      // under their final name and are swept on the next install.
      if (e is! Directory || p.basename(e.path).startsWith('.')) continue;
      try {
        final raw = await File(p.join(e.path, 'edition.json')).readAsString();
        out.add(BibleEdition.fromJson(json.decode(raw) as Map<String, dynamic>));
      } catch (_) {
        // Unreadable edition: skip it rather than break the reader.
      }
    }
    out.sort((a, b) => a.id.compareTo(b.id));
    return out;
  }

  @override
  Future<String?> readString(String editionId, String relativePath) async {
    // Ids and paths come from our own code, but never let one climb out.
    if (editionId.contains(RegExp(r'[/\\]')) || relativePath.contains('..')) {
      return null;
    }
    final f = File(p.join(_dir(editionId).path, relativePath));
    return await f.exists() ? f.readAsString() : null;
  }

  @override
  Future<BibleEdition> install(BibleCatalogEntry entry, Uint8List zip) async {
    if (sha256.convert(zip).toString() != entry.sha256) {
      throw BibleHashMismatch(entry.id);
    }
    await root.create(recursive: true);
    // Sweep leftovers from an install that was killed midway.
    await for (final e in root.list()) {
      if (p.basename(e.path).startsWith('.tmp-')) {
        await e.delete(recursive: true);
      }
    }
    final tmp = Directory(p.join(root.path, '.tmp-${entry.id}'));
    try {
      await tmp.create();
      final archive = ZipDecoder().decodeBytes(zip);
      var hasManifest = false;
      for (final f in archive) {
        if (!f.isFile) continue;
        final name = f.name;
        if (name.startsWith('/') || name.contains('..')) {
          throw BibleInstallException('bad path in archive: $name');
        }
        if (name == 'manifest.json') hasManifest = true;
        final out = File(p.join(tmp.path, name));
        await out.parent.create(recursive: true);
        await out.writeAsBytes(f.content as List<int>);
      }
      if (!hasManifest) throw const BibleInstallException('no manifest.json');
      final edition = entry.toEdition();
      await File(p.join(tmp.path, 'edition.json'))
          .writeAsString(json.encode(edition.toJson()));

      final dest = _dir(entry.id);
      if (await dest.exists()) await dest.delete(recursive: true);
      await tmp.rename(dest.path);
      return edition;
    } catch (_) {
      if (await tmp.exists()) await tmp.delete(recursive: true);
      rethrow;
    }
  }

  @override
  Future<void> delete(String editionId) async {
    final d = _dir(editionId);
    if (await d.exists()) await d.delete(recursive: true);
  }
}
