import 'dart:typed_data';

import 'package:openbaptisthymnal/features/bible/model/bible_catalog.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_edition.dart';

export 'installed_bible_store_stub.dart'
    if (dart.library.io) 'installed_bible_store_io.dart';

/// Where downloaded Bible editions live. The reader reads them through this
/// the same way it reads bundled assets. dart:io stays out of this file so
/// shared code (and the web build) can depend on it.
abstract class InstalledBibleStore {
  /// Editions currently installed, read from each folder's `edition.json`.
  Future<List<BibleEdition>> list();

  /// A file inside an installed edition (`manifest.json`, `books/JHN.json`),
  /// or null when the edition or file is not installed.
  Future<String?> readString(String editionId, String relativePath);

  /// Checks [zip] against `entry.sha256`, unzips to a temp folder, then renames
  /// it into place so a half-installed edition is never visible. Throws
  /// [BibleHashMismatch] (nothing written) or [BibleInstallException].
  Future<BibleEdition> install(BibleCatalogEntry entry, Uint8List zip);

  Future<void> delete(String editionId);
}

class BibleHashMismatch implements Exception {
  const BibleHashMismatch(this.id);
  final String id;
  @override
  String toString() => 'BibleHashMismatch($id)';
}

class BibleInstallException implements Exception {
  const BibleInstallException(this.message);
  final String message;
  @override
  String toString() => 'BibleInstallException($message)';
}

/// Installs nothing and reads nothing: the default (tests, web).
class NoopInstalledBibleStore implements InstalledBibleStore {
  const NoopInstalledBibleStore();

  @override
  Future<List<BibleEdition>> list() async => const [];

  @override
  Future<String?> readString(String editionId, String relativePath) async =>
      null;

  @override
  Future<BibleEdition> install(BibleCatalogEntry entry, Uint8List zip) =>
      throw const BibleInstallException('Downloads are not supported here');

  @override
  Future<void> delete(String editionId) async {}
}
