import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/features/hymn/data/sources/local/favorites_local_source.dart';
import 'package:openbaptisthymnal/features/hymn/model/language_pack.dart';
import 'package:openbaptisthymnal/features/hymn/providers/hymnal_provider.dart';

final favoritesLocalSourceProvider = Provider<FavoritesLocalSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FavoritesLocalSource(prefs);
});

/// Builds the language-scoped storage key for a favorite. Favorites are tied to
/// the language they were saved in, so the same hymn number can be favorited
/// independently in each language (e.g. `yo:hymn_0005` vs `en:hymn_0005`).
String favoriteKey(String language, String hymnId) => '$language:$hymnId';

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, Set<String>>(FavoritesNotifier.new);

class FavoritesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final source = ref.read(favoritesLocalSourceProvider);
    // 'yo' is the app's default language, so pre-existing favorites are
    // assumed Yoruba when upgrading from the old language-agnostic format.
    return source.migrateLegacyKeys('yo');
  }

  Future<void> toggle(String hymnId, String language) async {
    final source = ref.read(favoritesLocalSourceProvider);
    await source.toggleFavorite(favoriteKey(language, hymnId));
    state = source.getFavoriteIds();
  }

  bool isFavorite(String hymnId, String language) =>
      state.contains(favoriteKey(language, hymnId));

  Future<void> addFavorite(String hymnId, String language) async {
    final source = ref.read(favoritesLocalSourceProvider);
    await source.addFavorite(favoriteKey(language, hymnId));
    state = source.getFavoriteIds();
  }

  Future<void> removeFavorite(String hymnId, String language) async {
    final source = ref.read(favoritesLocalSourceProvider);
    await source.removeFavorite(favoriteKey(language, hymnId));
    state = source.getFavoriteIds();
  }
}

/// A favorited hymn paired with the language it was saved in.
typedef FavoriteHymn = ({HymnTranslation hymn, String language});

/// Derived provider — returns all favorited hymns, each resolved in the exact
/// language it was saved in. Switching the app's current language no longer
/// changes which translation a favorite shows.
final favoriteHymnsProvider = FutureProvider<List<FavoriteHymn>>((ref) async {
  final keys = ref.watch(favoritesProvider);
  if (keys.isEmpty) return [];

  final repo = ref.read(hymnalRepositoryProvider);

  // Group favorited hymn IDs by the language they were saved in so each pack
  // is loaded at most once.
  final idsByLanguage = <String, List<String>>{};
  for (final key in keys) {
    final sep = key.indexOf(':');
    if (sep < 0) continue;
    final language = key.substring(0, sep);
    final hymnId = key.substring(sep + 1);
    idsByLanguage.putIfAbsent(language, () => []).add(hymnId);
  }

  final result = <FavoriteHymn>[];
  for (final entry in idsByLanguage.entries) {
    final pack = await repo.getLanguagePack(entry.key);
    for (final id in entry.value) {
      final hymn = pack.hymns[id];
      if (hymn != null) {
        result.add((hymn: hymn.copyWith(id: id), language: entry.key));
      }
    }
  }

  result.sort((a, b) => a.hymn.number.compareTo(b.hymn.number));
  return result;
});
