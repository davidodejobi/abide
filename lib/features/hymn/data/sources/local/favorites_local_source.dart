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

  Future<void> clearAll() async {
    await _prefs.remove(_key);
  }

  Future<void> _persist(Set<String> ids) async {
    await _prefs.setString(_key, jsonEncode(ids.toList()));
  }
}
