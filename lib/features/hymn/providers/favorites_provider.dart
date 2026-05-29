import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/features/hymn/data/sources/local/favorites_local_source.dart';
import 'package:openbaptisthymnal/features/hymn/model/language_pack.dart';
import 'package:openbaptisthymnal/features/hymn/providers/hymnal_provider.dart';

final favoritesLocalSourceProvider = Provider<FavoritesLocalSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FavoritesLocalSource(prefs);
});

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, Set<String>>(FavoritesNotifier.new);

class FavoritesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final source = ref.read(favoritesLocalSourceProvider);
    return source.getFavoriteIds();
  }

  Future<void> toggle(String hymnId) async {
    final source = ref.read(favoritesLocalSourceProvider);
    await source.toggleFavorite(hymnId);
    state = source.getFavoriteIds();
  }

  bool isFavorite(String hymnId) => state.contains(hymnId);

  Future<void> addFavorite(String hymnId) async {
    final source = ref.read(favoritesLocalSourceProvider);
    await source.addFavorite(hymnId);
    state = source.getFavoriteIds();
  }

  Future<void> removeFavorite(String hymnId) async {
    final source = ref.read(favoritesLocalSourceProvider);
    await source.removeFavorite(hymnId);
    state = source.getFavoriteIds();
  }
}

/// Derived provider — returns all HymnTranslations that are currently favorited.
///
/// Language-agnostic: each hymn is resolved using the current language first,
/// falling back to any available language if the hymn has no translation in
/// the current language. This prevents favorited hymns from disappearing when
/// the user switches languages.
final favoriteHymnsProvider = FutureProvider<List<HymnTranslation>>((ref) async {
  final favoriteIds = ref.watch(favoritesProvider);
  if (favoriteIds.isEmpty) return [];

  final currentLang = ref.watch(languageProvider);
  final repo = ref.read(hymnalRepositoryProvider);

  final index = await repo.getHymnalIndex();
  final allLanguages = index.orders.keys.toList();

  final currentPack = await repo.getLanguagePack(currentLang);

  // Determine which favorited hymns are missing from the current language pack.
  final missingIds =
      favoriteIds.where((id) => !currentPack.hymns.containsKey(id)).toSet();

  // For missing hymns, load only the language packs that actually contain them.
  final fallbackPacks = <String, LanguagePack>{};
  if (missingIds.isNotEmpty) {
    for (final lang in allLanguages) {
      if (lang == currentLang) continue;
      final langIds = Set<String>.from(index.orders[lang] ?? const []);
      if (missingIds.any(langIds.contains)) {
        fallbackPacks[lang] = await repo.getLanguagePack(lang);
      }
    }
  }

  final result = <HymnTranslation>[];
  for (final id in favoriteIds) {
    if (currentPack.hymns.containsKey(id)) {
      result.add(currentPack.hymns[id]!.copyWith(id: id));
    } else {
      for (final pack in fallbackPacks.values) {
        if (pack.hymns.containsKey(id)) {
          result.add(pack.hymns[id]!.copyWith(id: id));
          break;
        }
      }
    }
  }

  return result;
});
