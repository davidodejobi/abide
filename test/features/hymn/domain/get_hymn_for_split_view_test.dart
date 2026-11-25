import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/hymn/data/hymnal_repository.dart';
import 'package:openbaptisthymnal/features/hymn/domain/get_hymn_for_split_view.dart';
import 'package:openbaptisthymnal/features/hymn/model/hymnal_core.dart';
import 'package:openbaptisthymnal/features/hymn/model/hymnal_index.dart';
import 'package:openbaptisthymnal/features/hymn/model/language_pack.dart';
import 'package:openbaptisthymnal/features/hymn/model/lyrics.dart';
import 'package:openbaptisthymnal/features/hymn/model/stanza.dart';

class _FakeHymnalRepository implements HymnalRepository {
  final Map<String, LanguagePack> packs;
  final Map<String, Map<String, String>> tables;

  _FakeHymnalRepository(this.packs, {this.tables = const {}});

  @override
  Future<HymnalCore> getHymnalCore() => throw UnimplementedError();

  @override
  Future<HymnalIndex> getHymnalIndex() => throw UnimplementedError();

  @override
  Future<LanguagePack> getLanguagePack(String languageCode) async =>
      packs[languageCode]!;

  @override
  Future<Map<String, String>> getPairTable(String languageCode) async =>
      tables[languageCode] ?? const {};
}

HymnTranslation _translation(String title, int number) => HymnTranslation(
    title: title, number: number, lyrics: const Lyrics(stanzas: []));

HymnTranslation _translationWithLyrics(
        String title, int number, String stanzaText) =>
    HymnTranslation(
      title: title,
      number: number,
      lyrics: Lyrics(stanzas: [Stanza(index: 1, text: stanzaText)]),
    );

void main() {
  group('GetHymnForSplitView', () {
    late GetHymnForSplitView useCase;

    setUp(() {
      // yo is the canonical id space; en ids deliberately do NOT line up:
      // en hymn_0001 is a different song from yo hymn_0001.
      final repo = _FakeHymnalRepository({
        'yo': LanguagePack(
          language: 'yo',
          hymnalName: 'Iwe Orin',
          hymns: {
            'hymn_0001': _translation('Doxology YO', 1),
            'hymn_0003': _translation('All People YO', 3),
          },
        ),
        'en': LanguagePack(
          language: 'en',
          hymnalName: 'Baptist Hymnal',
          hymns: {
            'hymn_0001': _translation('Holy Holy Holy EN', 1),
            'hymn_0004': _translation('All People EN', 4),
          },
        ),
      }, tables: {
        'en': {'hymn_0003': 'hymn_0004'},
      });
      useCase = GetHymnForSplitView(repo);
    });

    test('returns single translation for one language', () async {
      final result = await useCase('hymn_0001', ['yo'], fromLanguage: 'yo');
      expect(result.length, 1);
      expect(result['yo']?.title, 'Doxology YO');
    });

    test('pairs by content, not by id (yo -> en)', () async {
      final result =
          await useCase('hymn_0003', ['yo', 'en'], fromLanguage: 'yo');
      expect(result['yo']?.title, 'All People YO');
      expect(result['en']?.title, 'All People EN');
    });

    test('pairs by content, not by id (en -> yo)', () async {
      final result =
          await useCase('hymn_0004', ['en', 'yo'], fromLanguage: 'en');
      expect(result['en']?.title, 'All People EN');
      expect(result['yo']?.title, 'All People YO');
    });

    test('unpaired yo hymn returns no English, never the same-id song',
        () async {
      final result =
          await useCase('hymn_0001', ['yo', 'en'], fromLanguage: 'yo');
      expect(result.containsKey('yo'), isTrue);
      expect(result.containsKey('en'), isFalse);
    });

    test('unpaired en hymn returns no Yoruba', () async {
      final result =
          await useCase('hymn_0001', ['en', 'yo'], fromLanguage: 'en');
      expect(result['en']?.title, 'Holy Holy Holy EN');
      expect(result.containsKey('yo'), isFalse);
    });

    test('language without a pair table gets nothing', () async {
      final result =
          await useCase('hymn_0003', ['yo', 'ig'], fromLanguage: 'yo');
      expect(result.keys, ['yo']);
    });

    test('returns empty map when hymnId exists in no pack', () async {
      final result =
          await useCase('hymn_9999', ['yo', 'en'], fromLanguage: 'yo');
      expect(result, isEmpty);
    });

    test('returns empty map when languages list is empty', () async {
      final result = await useCase('hymn_0001', [], fromLanguage: 'yo');
      expect(result, isEmpty);
    });

    test('preserves translation number and lyrics', () async {
      final repo = _FakeHymnalRepository({
        'yo': LanguagePack(
          language: 'yo',
          hymnalName: 'Test',
          hymns: {
            'hymn_0001': _translationWithLyrics('Hymn', 120, 'E fi iyin'),
          },
        ),
      });
      final result = await GetHymnForSplitView(repo)('hymn_0001', ['yo'],
          fromLanguage: 'yo');
      expect(result['yo']?.number, 120);
      expect(result['yo']?.lyrics.stanzas[0].text, 'E fi iyin');
    });
  });
}
