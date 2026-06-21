import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/hymn/data/hymnal_repository.dart';
import 'package:openbaptisthymnal/features/hymn/model/hymnal_core.dart';
import 'package:openbaptisthymnal/features/hymn/model/hymnal_index.dart';
import 'package:openbaptisthymnal/features/hymn/model/language_pack.dart';
import 'package:openbaptisthymnal/features/hymn/model/lyrics.dart';
import 'package:openbaptisthymnal/features/hymn/providers/hymnal_provider.dart';
import 'package:openbaptisthymnal/features/hymn/ui/viewmodels/hymns_viewmodel.dart';

class _FakeHymnalRepository implements HymnalRepository {
  _FakeHymnalRepository(this.packs);
  final Map<String, LanguagePack> packs;

  @override
  Future<HymnalCore> getHymnalCore() => throw UnimplementedError();

  @override
  Future<HymnalIndex> getHymnalIndex() => throw UnimplementedError();

  @override
  Future<LanguagePack> getLanguagePack(String code) async => packs[code]!;
}

HymnTranslation _t(String title, int number) => HymnTranslation(
      title: title,
      number: number,
      lyrics: const Lyrics(stanzas: []),
    );

void main() {
  group('hymnInLanguageProvider', () {
    test('returns the translation when the hymn exists in the language pack',
        () async {
      final repo = _FakeHymnalRepository({
        'en': LanguagePack(
          language: 'en',
          hymnalName: 'B',
          hymns: {'hymn_0001': _t('Amazing Grace', 1)},
        ),
      });
      final container = ProviderContainer(overrides: [
        hymnalRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final result = await container.read(
          hymnInLanguageProvider(const HymnInLanguageKey('hymn_0001', 'en'))
              .future);
      expect(result?.title, 'Amazing Grace');
    });

    test('returns null when the hymn is missing from the pack', () async {
      final repo = _FakeHymnalRepository({
        'en': LanguagePack(
          language: 'en',
          hymnalName: 'B',
          hymns: {'hymn_0001': _t('A', 1)},
        ),
      });
      final container = ProviderContainer(overrides: [
        hymnalRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final result = await container.read(
          hymnInLanguageProvider(const HymnInLanguageKey('hymn_9999', 'en'))
              .future);
      expect(result, isNull);
    });

    test(
        'different language inputs are independent (yo and en cached separately)',
        () async {
      final repo = _FakeHymnalRepository({
        'en': LanguagePack(
          language: 'en',
          hymnalName: 'B',
          hymns: {'hymn_0001': _t('English Title', 1)},
        ),
        'yo': LanguagePack(
          language: 'yo',
          hymnalName: 'I',
          hymns: {'hymn_0001': _t('Yoruba Title', 1)},
        ),
      });
      final container = ProviderContainer(overrides: [
        hymnalRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final en = await container.read(
          hymnInLanguageProvider(const HymnInLanguageKey('hymn_0001', 'en'))
              .future);
      final yo = await container.read(
          hymnInLanguageProvider(const HymnInLanguageKey('hymn_0001', 'yo'))
              .future);

      expect(en?.title, 'English Title');
      expect(yo?.title, 'Yoruba Title');
    });
  });
}
