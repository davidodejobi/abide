import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/hymn/data/sources/local/favorites_local_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('FavoritesLocalSource', () {
    late FavoritesLocalSource source;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      source = FavoritesLocalSource(prefs);
    });

    test('getFavoriteIds returns empty set when nothing stored', () {
      expect(source.getFavoriteIds(), isEmpty);
    });

    test('addFavorite persists a hymn ID', () async {
      await source.addFavorite('hymn_0001');
      expect(source.getFavoriteIds(), contains('hymn_0001'));
    });

    test('addFavorite is idempotent — duplicate does not grow the set',
        () async {
      await source.addFavorite('hymn_0001');
      await source.addFavorite('hymn_0001');
      expect(source.getFavoriteIds().length, 1);
    });

    test('removeFavorite removes a previously added hymn ID', () async {
      await source.addFavorite('hymn_0001');
      await source.removeFavorite('hymn_0001');
      expect(source.getFavoriteIds(), isNot(contains('hymn_0001')));
    });

    test('removeFavorite on non-existent ID is a no-op', () async {
      await source.removeFavorite('hymn_9999');
      expect(source.getFavoriteIds(), isEmpty);
    });

    test('isFavorite returns false when ID is not in set', () {
      expect(source.isFavorite('hymn_0001'), isFalse);
    });

    test('isFavorite returns true after addFavorite', () async {
      await source.addFavorite('hymn_0001');
      expect(source.isFavorite('hymn_0001'), isTrue);
    });

    test('isFavorite returns false after removeFavorite', () async {
      await source.addFavorite('hymn_0001');
      await source.removeFavorite('hymn_0001');
      expect(source.isFavorite('hymn_0001'), isFalse);
    });

    test('toggleFavorite adds when not present', () async {
      await source.toggleFavorite('hymn_0002');
      expect(source.isFavorite('hymn_0002'), isTrue);
    });

    test('toggleFavorite removes when already present', () async {
      await source.addFavorite('hymn_0002');
      await source.toggleFavorite('hymn_0002');
      expect(source.isFavorite('hymn_0002'), isFalse);
    });

    test('clearAll empties all stored favorites', () async {
      await source.addFavorite('hymn_0001');
      await source.addFavorite('hymn_0002');
      await source.clearAll();
      expect(source.getFavoriteIds(), isEmpty);
    });

    test('getFavoriteIds returns all added IDs across multiple adds', () async {
      await source.addFavorite('hymn_0001');
      await source.addFavorite('hymn_0002');
      await source.addFavorite('hymn_0003');
      final ids = source.getFavoriteIds();
      expect(ids, containsAll(['hymn_0001', 'hymn_0002', 'hymn_0003']));
      expect(ids.length, 3);
    });

    test('data persists across FavoritesLocalSource instances (same prefs)',
        () async {
      await source.addFavorite('hymn_0001');
      // Create a second instance backed by the same prefs object
      final prefs = await SharedPreferences.getInstance();
      final source2 = FavoritesLocalSource(prefs);
      expect(source2.isFavorite('hymn_0001'), isTrue);
    });
  });
}
