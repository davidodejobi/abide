import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/features/hymn/providers/favorites_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ProviderContainer _makeContainer() {
//   SharedPreferences.setMockInitialValues({});
//   return ProviderContainer(
//     overrides: [
//       sharedPreferencesProvider.overrideWith(
//         (ref) => throw UnimplementedError('use async init below'),
//       ),
//     ],
//   );
// }

/// Returns a container pre-wired with a real SharedPreferences instance.
Future<ProviderContainer> makeContainer() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );
  return container;
}

void main() {
  group('FavoritesNotifier', () {
    test('initial state is empty', () async {
      final container = await makeContainer();
      addTearDown(container.dispose);
      expect(container.read(favoritesProvider), isEmpty);
    });

    test('toggle adds a hymn ID when not present', () async {
      final container = await makeContainer();
      addTearDown(container.dispose);
      await container.read(favoritesProvider.notifier).toggle('hymn_0001');
      expect(container.read(favoritesProvider), contains('hymn_0001'));
    });

    test('toggle removes a hymn ID when already present', () async {
      final container = await makeContainer();
      addTearDown(container.dispose);
      await container.read(favoritesProvider.notifier).toggle('hymn_0001');
      await container.read(favoritesProvider.notifier).toggle('hymn_0001');
      expect(container.read(favoritesProvider), isNot(contains('hymn_0001')));
    });

    test('isFavorite returns false for unknown ID', () async {
      final container = await makeContainer();
      addTearDown(container.dispose);
      expect(
        container.read(favoritesProvider.notifier).isFavorite('hymn_9999'),
        isFalse,
      );
    });

    test('isFavorite returns true after toggle', () async {
      final container = await makeContainer();
      addTearDown(container.dispose);
      await container.read(favoritesProvider.notifier).toggle('hymn_0001');
      expect(
        container.read(favoritesProvider.notifier).isFavorite('hymn_0001'),
        isTrue,
      );
    });

    test('addFavorite adds a hymn ID to state', () async {
      final container = await makeContainer();
      addTearDown(container.dispose);
      await container.read(favoritesProvider.notifier).addFavorite('hymn_0002');
      expect(container.read(favoritesProvider), contains('hymn_0002'));
    });

    test('removeFavorite removes a hymn ID from state', () async {
      final container = await makeContainer();
      addTearDown(container.dispose);
      await container.read(favoritesProvider.notifier).addFavorite('hymn_0002');
      await container
          .read(favoritesProvider.notifier)
          .removeFavorite('hymn_0002');
      expect(container.read(favoritesProvider), isNot(contains('hymn_0002')));
    });

    test('state reflects multiple independent favorites', () async {
      final container = await makeContainer();
      addTearDown(container.dispose);
      await container.read(favoritesProvider.notifier).addFavorite('hymn_0001');
      await container.read(favoritesProvider.notifier).addFavorite('hymn_0002');
      final state = container.read(favoritesProvider);
      expect(state, containsAll(['hymn_0001', 'hymn_0002']));
    });

    test('state is persisted to SharedPreferences via FavoritesLocalSource',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      await container.read(favoritesProvider.notifier).addFavorite('hymn_0001');

      // A fresh container backed by the same prefs sees the persisted state
      final container2 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container2.dispose);
      expect(container2.read(favoritesProvider), contains('hymn_0001'));
    });
  });
}
