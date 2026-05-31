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

    test('toggle adds a language-scoped key when not present', () async {
      final container = await makeContainer();
      addTearDown(container.dispose);
      await container
          .read(favoritesProvider.notifier)
          .toggle('hymn_0001', 'yo');
      expect(container.read(favoritesProvider), contains('yo:hymn_0001'));
    });

    test('toggle removes a key when already present', () async {
      final container = await makeContainer();
      addTearDown(container.dispose);
      await container
          .read(favoritesProvider.notifier)
          .toggle('hymn_0001', 'yo');
      await container
          .read(favoritesProvider.notifier)
          .toggle('hymn_0001', 'yo');
      expect(
          container.read(favoritesProvider), isNot(contains('yo:hymn_0001')));
    });

    test('the same hymn is favorited independently per language', () async {
      final container = await makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(favoritesProvider.notifier);
      await notifier.toggle('hymn_0001', 'yo');
      await notifier.toggle('hymn_0001', 'en');
      expect(notifier.isFavorite('hymn_0001', 'yo'), isTrue);
      expect(notifier.isFavorite('hymn_0001', 'en'), isTrue);
      // Removing one language leaves the other untouched.
      await notifier.toggle('hymn_0001', 'yo');
      expect(notifier.isFavorite('hymn_0001', 'yo'), isFalse);
      expect(notifier.isFavorite('hymn_0001', 'en'), isTrue);
    });

    test('isFavorite returns false for unknown ID', () async {
      final container = await makeContainer();
      addTearDown(container.dispose);
      expect(
        container
            .read(favoritesProvider.notifier)
            .isFavorite('hymn_9999', 'yo'),
        isFalse,
      );
    });

    test('isFavorite returns true after toggle', () async {
      final container = await makeContainer();
      addTearDown(container.dispose);
      await container
          .read(favoritesProvider.notifier)
          .toggle('hymn_0001', 'yo');
      expect(
        container
            .read(favoritesProvider.notifier)
            .isFavorite('hymn_0001', 'yo'),
        isTrue,
      );
    });

    test('addFavorite adds a language-scoped key to state', () async {
      final container = await makeContainer();
      addTearDown(container.dispose);
      await container
          .read(favoritesProvider.notifier)
          .addFavorite('hymn_0002', 'yo');
      expect(container.read(favoritesProvider), contains('yo:hymn_0002'));
    });

    test('removeFavorite removes a key from state', () async {
      final container = await makeContainer();
      addTearDown(container.dispose);
      await container
          .read(favoritesProvider.notifier)
          .addFavorite('hymn_0002', 'yo');
      await container
          .read(favoritesProvider.notifier)
          .removeFavorite('hymn_0002', 'yo');
      expect(
          container.read(favoritesProvider), isNot(contains('yo:hymn_0002')));
    });

    test('state reflects multiple independent favorites', () async {
      final container = await makeContainer();
      addTearDown(container.dispose);
      await container
          .read(favoritesProvider.notifier)
          .addFavorite('hymn_0001', 'yo');
      await container
          .read(favoritesProvider.notifier)
          .addFavorite('hymn_0002', 'yo');
      final state = container.read(favoritesProvider);
      expect(state, containsAll(['yo:hymn_0001', 'yo:hymn_0002']));
    });

    test('legacy language-agnostic favorites migrate to default language',
        () async {
      SharedPreferences.setMockInitialValues({
        'favorites_hymn_ids': '["hymn_0001","hymn_0002"]',
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final state = container.read(favoritesProvider);
      expect(state, containsAll(['yo:hymn_0001', 'yo:hymn_0002']));
    });

    test('state is persisted to SharedPreferences via FavoritesLocalSource',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      await container
          .read(favoritesProvider.notifier)
          .addFavorite('hymn_0001', 'yo');

      // A fresh container backed by the same prefs sees the persisted state
      final container2 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container2.dispose);
      expect(container2.read(favoritesProvider), contains('yo:hymn_0001'));
    });
  });
}
