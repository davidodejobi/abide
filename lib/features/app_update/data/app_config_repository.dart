import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:openbaptisthymnal/core/storage/storage_service.dart';
import 'package:openbaptisthymnal/features/app_update/domain/app_config.dart';

// ponytail: placeholder. Hosting this JSON file (any static HTTPS host) is an
// owner step; until then the fetch fails and the app fails open (no gate).
const kAppConfigUrl = 'https://config.example.invalid/lumway/app_config.json';

typedef AppConfigFetcher = Future<AppConfig?> Function();

/// Fetches the remote config and keeps the last good copy in storage.
class AppConfigRepository {
  AppConfigRepository(this._storage, {AppConfigFetcher? fetcher})
      : _fetcher = fetcher ?? _fetchOverHttp;

  final StorageService _storage;
  final AppConfigFetcher _fetcher;

  /// The last good config and when it was fetched, or null if none/corrupt.
  ({AppConfig config, DateTime checkedAt})? cached() {
    final raw = _storage.getAppConfigCache();
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return (
        config: AppConfig.fromJson(map['config'] as Map<String, dynamic>),
        checkedAt: DateTime.parse(map['checkedAt'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  /// Fetches and caches. Returns null on any failure.
  Future<({AppConfig config, DateTime checkedAt})?> refresh() async {
    final config = await _fetcher();
    if (config == null) return null;
    final now = DateTime.now();
    await _storage.saveAppConfigCache(
      jsonEncode({'config': config.toJson(), 'checkedAt': now.toIso8601String()}),
    );
    return (config: config, checkedAt: now);
  }

  static Future<AppConfig?> _fetchOverHttp() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5);
    try {
      return await () async {
        final request = await client.getUrl(Uri.parse(kAppConfigUrl));
        final response = await request.close();
        if (response.statusCode != 200) return null;
        final body = await response.transform(utf8.decoder).join();
        return AppConfig.fromJson(jsonDecode(body) as Map<String, dynamic>);
      }()
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
