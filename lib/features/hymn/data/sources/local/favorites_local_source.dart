import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class FavoritesLocalSource {
  final SharedPreferences _prefs;

  FavoritesLocalSource(this._prefs);

  static const String _key = 'favorites_hymn_ids';

  Set<String> getFavoriteIds() {
    final raw = _prefs.getString(_key);
    if (raw == null) return {};
    final list = (jsonDecode(raw) as List).cast<String>();
    return list.toSet();
  }

  Future<void> addFavorite(String hymnId) async {
    final ids = getFavoriteIds()..add(hymnId);
    await _persist(ids);
  }

  Future<void> removeFavorite(String hymnId) async {
    final ids = getFavoriteIds()..remove(hymnId);
    await _persist(ids);
  }

  Future<void> toggleFavorite(String hymnId) async {
    if (isFavorite(hymnId)) {
      await removeFavorite(hymnId);
    } else {
      await addFavorite(hymnId);
    }
  }

  bool isFavorite(String hymnId) => getFavoriteIds().contains(hymnId);

  /// Upgrades legacy language-agnostic favorites ("hymn_0005") to language-
  /// scoped keys ("yo:hymn_0005") so a favorite stays tied to the language it
  /// was saved in. Idempotent — keys that already carry a language are left
  /// untouched. Returns the (possibly migrated) set.
  Set<String> migrateLegacyKeys(String defaultLanguage) {
    final ids = getFavoriteIds();
    if (ids.every((k) => k.contains(':'))) return ids;
    final migrated = {
      for (final k in ids) k.contains(':') ? k : '$defaultLanguage:$k',
    };
    _persist(migrated);
    return migrated;
  }

  Future<void> clearAll() async {
    await _prefs.remove(_key);
  }

  Future<void> _persist(Set<String> ids) async {
    await _prefs.setString(_key, jsonEncode(ids.toList()));
  }
}
