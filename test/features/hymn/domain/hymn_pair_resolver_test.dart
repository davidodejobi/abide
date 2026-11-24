import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/utils/json_loader.dart';
import 'package:openbaptisthymnal/features/hymn/data/hymnal_repository.dart';
import 'package:openbaptisthymnal/features/hymn/domain/hymn_pair_resolver.dart';
import 'package:openbaptisthymnal/features/hymn/model/hymnal_core.dart';
import 'package:openbaptisthymnal/features/hymn/model/hymnal_index.dart';
import 'package:openbaptisthymnal/features/hymn/model/language_pack.dart';

class _FakeRepo implements HymnalRepository {
  _FakeRepo(this.tables);
  final Map<String, Map<String, String>> tables;

  @override
  Future<HymnalCore> getHymnalCore() => throw UnimplementedError();

  @override
  Future<HymnalIndex> getHymnalIndex() => throw UnimplementedError();

  @override
  Future<LanguagePack> getLanguagePack(String languageCode) =>
      throw UnimplementedError();

  @override
  Future<Map<String, String>> getPairTable(String languageCode) async =>
      tables[languageCode] ?? const {};
}

/// Reads assets straight from disk so the repository's real parsing (high
/// only, missing file -> empty) is exercised without a Flutter binding.
class _DiskLoader extends JsonLoader {
  @override
  Future<Map<String, dynamic>> loadJson(String path) async =>
      json.decode(await File(path).readAsString()) as Map<String, dynamic>;
}

void main() {
  group('HymnPairResolver', () {
    final resolver = HymnPairResolver(_FakeRepo({
      'en': {'hymn_0003': 'hymn_0004'},
    }));

    test('same language is identity', () async {
      expect(await resolver.idIn('yo', 'hymn_0001', fromLanguage: 'yo'),
          'hymn_0001');
      expect(await resolver.idIn('en', 'hymn_0001', fromLanguage: 'en'),
          'hymn_0001');
    });

    test('yo -> en goes through the table', () async {
      expect(await resolver.idIn('en', 'hymn_0003', fromLanguage: 'yo'),
          'hymn_0004');
    });

    test('unpaired yo hymn has no en id (not the same-id song)', () async {
      expect(
          await resolver.idIn('en', 'hymn_0001', fromLanguage: 'yo'), isNull);
    });

    test('en -> yo reverse lookup', () async {
      expect(await resolver.idIn('yo', 'hymn_0004', fromLanguage: 'en'),
          'hymn_0003');
      expect(await resolver.canonicalId('hymn_0004', fromLanguage: 'en'),
          'hymn_0003');
    });

    test('unpaired en hymn has no yo id', () async {
      expect(
          await resolver.idIn('yo', 'hymn_0001', fromLanguage: 'en'), isNull);
    });

    test('language with no table has no pair either way', () async {
      expect(
          await resolver.idIn('ig', 'hymn_0003', fromLanguage: 'yo'), isNull);
      expect(
          await resolver.idIn('yo', 'hymn_0003', fromLanguage: 'ig'), isNull);
    });

    test('en -> other language goes via the canonical id', () async {
      final r = HymnPairResolver(_FakeRepo({
        'en': {'hymn_0003': 'hymn_0004'},
        'ig': {'hymn_0003': 'hymn_0900'},
      }));
      expect(await r.idIn('ig', 'hymn_0004', fromLanguage: 'en'), 'hymn_0900');
    });
  });

  group('HymnalRepositoryImpl.getPairTable', () {
    final repo = HymnalRepositoryImpl(_DiskLoader());

    test('only high-confidence pairs are used', () async {
      final raw =
          json.decode(File('assets/hymnal/pairs/yo_en.json').readAsStringSync())
              as Map<String, dynamic>;
      final all = raw['pairs'] as Map<String, dynamic>;
      final high =
          all.values.where((v) => (v as Map)['confidence'] == 'high').length;
      final medium =
          all.values.where((v) => (v as Map)['confidence'] == 'medium').length;
      expect(medium, greaterThan(0), reason: 'file keeps medium for review');

      final table = await repo.getPairTable('en');
      expect(table.length, high);
      expect(table.length, lessThan(all.length));
    });

    test('a language with no table file gives an empty table', () async {
      expect(await repo.getPairTable('zz'), isEmpty);
    });
  });

  group('shipped yo <-> en table', () {
    final repo = HymnalRepositoryImpl(_DiskLoader());

    Map<String, dynamic> pack(String lang) => (json.decode(
            File('assets/hymnal/languages/$lang.json').readAsStringSync())
        as Map<String, dynamic>)['hymns'] as Map<String, dynamic>;

    test('yo hymn_0003 pairs with All People That on Earth Do Dwell', () async {
      final en = await HymnPairResolver(repo)
          .idIn('en', 'hymn_0003', fromLanguage: 'yo');
      expect(en, isNotNull);
      expect(pack('en')[en]['title'], 'All People That on Earth Do Dwell');
    });

    test('yo hymn_0001 is NOT paired with en hymn_0001', () async {
      final en = await HymnPairResolver(repo)
          .idIn('en', 'hymn_0001', fromLanguage: 'yo');
      expect(en, isNot('hymn_0001'));
    });

    test('Holy, Holy, Holy: yo and en agree, and en reverses back', () async {
      final r = HymnPairResolver(repo);
      final yoId = await r.canonicalId('hymn_0001', fromLanguage: 'en');
      expect(pack('en')['hymn_0001']['title'], 'Holy, Holy, Holy');
      expect(yoId, isNotNull);
      expect(pack('yo')[yoId]['title'], startsWith('Mimo, Mimo, Mimo'));
      expect(await r.idIn('en', yoId!, fromLanguage: 'yo'), 'hymn_0001');
    });

    test('every pair points at ids that exist, and no en id is reused',
        () async {
      final table = await repo.getPairTable('en');
      final yo = pack('yo');
      final en = pack('en');
      for (final e in table.entries) {
        expect(yo.containsKey(e.key), isTrue, reason: e.key);
        expect(en.containsKey(e.value), isTrue, reason: e.value);
      }
      expect(table.values.toSet().length, table.length);
    });
  });
}
