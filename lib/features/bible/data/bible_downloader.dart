import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:openbaptisthymnal/features/bible/data/sources/local/installed_bible_store.dart';
import 'package:openbaptisthymnal/features/bible/data/sources/remote/bible_catalog_source.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_catalog.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_edition.dart';

/// Downloads an edition's zip with progress, then hands it to the store, which
/// checks the sha256 and installs it atomically.
class BibleDownloader {
  BibleDownloader(this._client, this._store, {this.base = kAssetsCdnBase});

  final http.Client _client;
  final InstalledBibleStore _store;
  final String base;

  /// [onProgress] gets 0..1. Throws [http.ClientException] on network or HTTP
  /// failure, [BibleHashMismatch] if the bytes are not what the catalog said.
  Future<BibleEdition> download(
    BibleCatalogEntry entry, {
    void Function(double)? onProgress,
  }) async {
    final res = await _client
        .send(http.Request('GET', bibleCdnUri(entry.url, base: base)));
    if (res.statusCode != 200) {
      throw http.ClientException('download HTTP ${res.statusCode}');
    }
    final total = res.contentLength ?? entry.sizeBytes;
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in res.stream) {
      bytes.add(chunk);
      if (total > 0) {
        onProgress?.call((bytes.length / total).clamp(0.0, 1.0));
      }
    }
    onProgress?.call(1);
    return _store.install(entry, bytes.takeBytes());
  }

  Future<void> remove(String editionId) => _store.delete(editionId);
}
