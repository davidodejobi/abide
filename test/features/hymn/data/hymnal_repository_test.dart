import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/utils/json_loader.dart';
import 'package:openbaptisthymnal/features/hymn/data/hymnal_repository.dart';

class _Loader extends JsonLoader {
  _Loader(this._load);
  final Map<String, dynamic> Function() _load;

  @override
  Future<Map<String, dynamic>> loadJson(String path) async => _load();
}

void main() {
  HymnalRepositoryImpl repo(Map<String, dynamic> Function() load) =>
      HymnalRepositoryImpl(_Loader(load));

  test('missing pair table is an empty table', () async {
    final r = repo(() => throw FlutterError('Unable to load asset'));
    expect(await r.getPairTable('en'), isEmpty);
  });

  test('only high confidence pairs are used', () async {
    final r = repo(() => {
          'pairs': {
            'hymn_0001': {'confidence': 'high', 'en': 'hymn_0009'},
            'hymn_0002': {'confidence': 'medium', 'en': 'hymn_0010'},
          },
        });
    expect(await r.getPairTable('en'), {'hymn_0001': 'hymn_0009'});
  });

  test('a malformed table throws instead of reading as empty', () async {
    expect(repo(() => throw const FormatException('bad json')).getPairTable('en'),
        throwsFormatException);
    expect(
        repo(() => {
              'pairs': {'hymn_0001': 'oops'},
            }).getPairTable('en'),
        throwsA(isA<TypeError>()));
  });
}
