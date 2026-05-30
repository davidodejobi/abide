import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/hymn/data/hymnal_repository.dart';
import 'package:openbaptisthymnal/features/hymn/domain/get_hymns_by_language.dart';
import 'package:openbaptisthymnal/features/hymn/model/hymn.dart';
import 'package:openbaptisthymnal/features/hymn/model/hymnal_core.dart';
import 'package:openbaptisthymnal/features/hymn/model/hymnal_index.dart';
import 'package:openbaptisthymnal/features/hymn/model/language_pack.dart';
import 'package:openbaptisthymnal/features/hymn/model/lyrics.dart';
import 'package:openbaptisthymnal/features/hymn/model/stanza.dart';

// ---------------------------------------------------------------------------
// Fake repository — no Flutter binding or asset loading required
// ---------------------------------------------------------------------------
class _FakeHymnalRepository implements HymnalRepository {
  final HymnalCore core;
  final HymnalIndex index;
  final Map<String, LanguagePack> packs;

  _FakeHymnalRepository({
    required this.core,
    required this.index,
    required this.packs,
  });

  @override
  Future<HymnalCore> getHymnalCore() async => core;

  @override
  Future<HymnalIndex> getHymnalIndex() async => index;

  @override
  Future<LanguagePack> getLanguagePack(String languageCode) async =>
      packs[languageCode]!;
}

// ---------------------------------------------------------------------------
// Test data helpers
// ---------------------------------------------------------------------------
Lyrics _emptyLyrics() => const Lyrics(stanzas: []);
Lyrics _lyricsWithStanza(String text) =>
    Lyrics(stanzas: [Stanza(index: 1, text: text)]);

HymnTranslation _translation(String title, int number) =>
    HymnTranslation(title: title, number: number, lyrics: _emptyLyrics());

void main() {
  group('GetHymnsByLanguage', () {
    late _FakeHymnalRepository repo;
    late GetHymnsByLanguage useCase;

    setUp(() {
      repo = _FakeHymnalRepository(
        core: const HymnalCore(
          schemaVersion: '1.0',
          hymnalId: 'test',
          hymns: {
            'hymn_0001': Hymn(category: 'praise'),
            'hymn_0002': Hymn(category: 'worship'),
            'hymn_0003': Hymn(category: 'praise'),
          },
        ),
        index: const HymnalIndex(orders: {
          'yor': ['hymn_0001', 'hymn_0002', 'hymn_0003'],
          'eng': ['hymn_0003', 'hymn_0001'],
        }),
        packs: {
          'yor': LanguagePack(
            language: 'yor',
            hymnalName: 'Iwe Orin',
            hymns: {
              'hymn_0001': _translation('Hymn One YOR', 1),
              'hymn_0002': _translation('Hymn Two YOR', 2),
              'hymn_0003': _translation('Hymn Three YOR', 3),
            },
          ),
          'eng': LanguagePack(
            language: 'eng',
            hymnalName: 'Baptist Hymnal',
            hymns: {
              'hymn_0001': _translation('Hymn One ENG', 120),
              'hymn_0003': _translation('Hymn Three ENG', 305),
            },
          ),
        },
      );
      useCase = GetHymnsByLanguage(repo);
    });

    test('returns hymns in index order for Yoruba', () async {
      final result = await useCase('yor');
      expect(result.length, 3);
      expect(result[0].title, 'Hymn One YOR');
      expect(result[1].title, 'Hymn Two YOR');
      expect(result[2].title, 'Hymn Three YOR');
    });

    test('returns hymns in index order for English', () async {
      final result = await useCase('eng');
      expect(result.length, 2);
      expect(result[0].title, 'Hymn Three ENG');
      expect(result[1].title, 'Hymn One ENG');
    });

    test('returned translations carry the hymn ID', () async {
      final result = await useCase('yor');
      expect(result[0].id, 'hymn_0001');
      expect(result[1].id, 'hymn_0002');
      expect(result[2].id, 'hymn_0003');
    });

    test('returned translations carry correct numbers', () async {
      final result = await useCase('eng');
      expect(result[0].number, 305);
      expect(result[1].number, 120);
    });

    test('omits hymns present in core but missing from language pack',
        () async {
      // hymn_0002 is not in the English pack
      final result = await useCase('eng');
      final ids = result.map((h) => h.id).toList();
      expect(ids, isNot(contains('hymn_0002')));
    });

    test('returns empty list for unknown language code', () async {
      repo = _FakeHymnalRepository(
        core: repo.core,
        index: const HymnalIndex(orders: {}),
        packs: {
          'xx': const LanguagePack(language: 'xx', hymnalName: 'X', hymns: {})
        },
      );
      final result = await GetHymnsByLanguage(repo)('xx');
      expect(result, isEmpty);
    });

    test('stanzas are preserved in the returned translation', () async {
      final repoWithLyrics = _FakeHymnalRepository(
        core: repo.core,
        index: const HymnalIndex(orders: {
          'yor': ['hymn_0001'],
        }),
        packs: {
          'yor': LanguagePack(
            language: 'yor',
            hymnalName: 'Test',
            hymns: {
              'hymn_0001': HymnTranslation(
                title: 'With Lyrics',
                number: 1,
                lyrics: _lyricsWithStanza('E fi iyin fun Olorun'),
              ),
            },
          ),
        },
      );
      final result = await GetHymnsByLanguage(repoWithLyrics)('yor');
      expect(result[0].lyrics.stanzas[0].text, 'E fi iyin fun Olorun');
    });
  });
}
