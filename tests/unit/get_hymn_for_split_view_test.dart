import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/hymn/data/hymnal_repository.dart';
import 'package:openbaptisthymnal/features/hymn/domain/get_hymn_for_split_view.dart';
import 'package:openbaptisthymnal/features/hymn/model/hymnal_core.dart';
import 'package:openbaptisthymnal/features/hymn/model/hymnal_index.dart';
import 'package:openbaptisthymnal/features/hymn/model/language_pack.dart';
import 'package:openbaptisthymnal/features/hymn/model/lyrics.dart';
import 'package:openbaptisthymnal/features/hymn/model/stanza.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------
class _FakeHymnalRepository implements HymnalRepository {
  final Map<String, LanguagePack> packs;

  _FakeHymnalRepository(this.packs);

  @override
  Future<HymnalCore> getHymnalCore() => throw UnimplementedError();

  @override
  Future<HymnalIndex> getHymnalIndex() => throw UnimplementedError();

  @override
  Future<LanguagePack> getLanguagePack(String languageCode) async =>
      packs[languageCode]!;
}

// ---------------------------------------------------------------------------
// Test data
// ---------------------------------------------------------------------------
HymnTranslation _translation(String title, int number) =>
    HymnTranslation(title: title, number: number, lyrics: const Lyrics(stanzas: []));

HymnTranslation _translationWithLyrics(String title, int number, String stanzaText) =>
    HymnTranslation(
      title: title,
      number: number,
      lyrics: Lyrics(stanzas: [Stanza(index: 1, text: stanzaText)]),
    );

void main() {
  group('GetHymnForSplitView', () {
    late _FakeHymnalRepository repo;
    late GetHymnForSplitView useCase;

    setUp(() {
      repo = _FakeHymnalRepository({
        'yor': LanguagePack(
          language: 'yor',
          hymnalName: 'Iwe Orin',
          hymns: {
            'hymn_0001': _translation('Hymn One YOR', 1),
            'hymn_0002': _translation('Hymn Two YOR', 2),
          },
        ),
        'eng': LanguagePack(
          language: 'eng',
          hymnalName: 'Baptist Hymnal',
          hymns: {
            'hymn_0001': _translation('Hymn One ENG', 120),
          },
        ),
      });
      useCase = GetHymnForSplitView(repo);
    });

    test('returns single translation for one language', () async {
      final result = await useCase('hymn_0001', ['yor']);
      expect(result.length, 1);
      expect(result['yor']?.title, 'Hymn One YOR');
    });

    test('returns translations keyed by language code for multiple languages', () async {
      final result = await useCase('hymn_0001', ['yor', 'eng']);
      expect(result['yor']?.title, 'Hymn One YOR');
      expect(result['eng']?.title, 'Hymn One ENG');
    });

    test('omits language if hymnId is not in that pack', () async {
      // hymn_0002 exists in yor but not eng
      final result = await useCase('hymn_0002', ['yor', 'eng']);
      expect(result.containsKey('yor'), isTrue);
      expect(result.containsKey('eng'), isFalse);
    });

    test('returns empty map when hymnId exists in no pack', () async {
      final result = await useCase('hymn_9999', ['yor', 'eng']);
      expect(result, isEmpty);
    });

    test('returns empty map when languages list is empty', () async {
      final result = await useCase('hymn_0001', []);
      expect(result, isEmpty);
    });

    test('preserves translation number', () async {
      final result = await useCase('hymn_0001', ['eng']);
      expect(result['eng']?.number, 120);
    });

    test('preserves lyrics stanzas', () async {
      final repoWithLyrics = _FakeHymnalRepository({
        'yor': LanguagePack(
          language: 'yor',
          hymnalName: 'Test',
          hymns: {
            'hymn_0001': _translationWithLyrics('Hymn', 1, 'E fi iyin'),
          },
        ),
      });
      final result = await GetHymnForSplitView(repoWithLyrics)('hymn_0001', ['yor']);
      expect(result['yor']?.lyrics.stanzas[0].text, 'E fi iyin');
    });
  });
}
