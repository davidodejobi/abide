import 'package:openbaptisthymnal/features/hymn/data/hymnal_repository.dart';
import 'package:openbaptisthymnal/features/hymn/model/hymn.dart';
import 'package:openbaptisthymnal/features/hymn/model/hymnal_core.dart';
import 'package:openbaptisthymnal/features/hymn/model/hymnal_index.dart';
import 'package:openbaptisthymnal/features/hymn/model/language_pack.dart';
import 'package:openbaptisthymnal/features/hymn/model/lyrics.dart';
import 'package:openbaptisthymnal/features/hymn/model/stanza.dart';

/// A tiny in-memory hymnal: three hymns in English and Yorùbá.
class FakeHymnalRepository implements HymnalRepository {
  static const _titles = {
    'hymn_0001': 'Holy, Holy, Holy',
    'hymn_0003': 'To God Be the Glory',
    'hymn_0004': 'All People That on Earth Do Dwell',
  };

  static const _lines = {
    'hymn_0001': [
      'Holy, holy, holy! Lord God Almighty!\nEarly in the morning our song shall rise to Thee.',
      'Holy, holy, holy! All the saints adore Thee,\nCasting down their golden crowns around the glassy sea;',
    ],
    'hymn_0003': ['To God be the glory, great things He hath done'],
    'hymn_0004': ['All people that on earth do dwell, sing to the Lord'],
  };

  @override
  Future<HymnalCore> getHymnalCore() async => HymnalCore(
        schemaVersion: '1',
        hymnalId: 'test',
        hymns: {for (final id in _titles.keys) id: const Hymn(category: 'x')},
      );

  // The fake's packs share ids, so every hymn pairs with itself.
  @override
  Future<Map<String, String>> getPairTable(String languageCode) async =>
      {for (final id in _titles.keys) id: id};

  @override
  Future<HymnalIndex> getHymnalIndex() async => HymnalIndex(orders: {
        'en': _titles.keys.toList(),
        'yo': _titles.keys.toList(),
      });

  @override
  Future<LanguagePack> getLanguagePack(String code) async => LanguagePack(
        language: code,
        hymnalName: 'Test',
        hymns: {
          for (final e in _titles.entries)
            e.key: HymnTranslation(
              number: int.parse(e.key.substring(5)),
              title: code == 'yo' ? 'Mímọ́, ${e.value}' : e.value,
              lyrics: Lyrics(
                stanzas: [
                  for (var i = 0; i < _lines[e.key]!.length; i++)
                    Stanza(index: i + 1, text: _lines[e.key]![i]),
                ],
                chorus:
                    e.key == 'hymn_0001' ? 'Sing it out, sing it out' : null,
              ),
            ),
        },
      );
}
