import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:openbaptisthymnal/features/bible/model/bible_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Base URL of the static host that serves `bibles/catalog.json` and the zips.
const String kAssetsCdnBase = String.fromEnvironment(
  'ASSETS_CDN_BASE',
  defaultValue: 'https://lumway-assets.pages.dev',
);

Uri bibleCdnUri(String path, {String base = kAssetsCdnBase}) =>
    Uri.parse('${base.replaceAll(RegExp(r'/+$'), '')}/$path');

/// Fetches the Bible catalog and keeps the last good copy so the list still
/// shows offline.
class BibleCatalogSource {
  BibleCatalogSource(this._client, this._prefs, {this.base = kAssetsCdnBase});

  final http.Client _client;
  final SharedPreferences _prefs;
  final String base;

  static const _cacheKey = 'bible_catalog_cache';

  BibleCatalog? cached() {
    final raw = _prefs.getString(_cacheKey);
    if (raw == null) return null;
    try {
      return BibleCatalog.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Throws on network failure, a non-200, or a malformed body. Only a catalog
  /// that parses is cached.
  Future<BibleCatalog> fetch() async {
    final res = await _client
        .get(bibleCdnUri('bibles/catalog.json', base: base))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw http.ClientException('catalog HTTP ${res.statusCode}');
    }
    final catalog = BibleCatalog.fromJson(
        json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
    await _prefs.setString(_cacheKey, json.encode(catalog.toJson()));
    return catalog;
  }
}
