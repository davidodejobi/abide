import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/hymn/model/hymnal_core.dart';
import 'package:openbaptisthymnal/features/hymn/model/hymnal_index.dart';
import 'package:openbaptisthymnal/features/hymn/model/language_pack.dart';

void main() {
  group('Hymnal Data Models Test', () {
    setUp(() {
      WidgetsFlutterBinding.ensureInitialized();
    });

    test('HymnalCore parses successfully from core.json', () async {
      final jsonString = await rootBundle.loadString('assets/hymnal/core.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      final core = HymnalCore.fromJson(jsonMap);

      expect(core.hymns, isNotEmpty);
      final hymn1 = core.hymns['hymn_0001'];
      expect(hymn1, isNotNull);
      expect(hymn1?.category, isNotEmpty);
    });

    test('HymnalIndex parses successfully from index.json', () async {
      final jsonString =
          await rootBundle.loadString('assets/hymnal/index.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      final index = HymnalIndex.fromJson(jsonMap);

      expect(index.orders.keys, containsAll(['yo', 'en']));
      for (final order in index.orders.values) {
        expect(order, isNotEmpty);
        expect(order.first, startsWith('hymn_'));
      }
    });

    test('LanguagePack parses successfully from yo.json (Yoruba)', () async {
      final jsonString =
          await rootBundle.loadString('assets/hymnal/languages/yo.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      final pack = LanguagePack.fromJson(jsonMap);

      expect(pack.language, 'yor');
      expect(pack.hymns, isNotEmpty);

      final hymn1 = pack.hymns['hymn_0001'];
      expect(hymn1, isNotNull);
      expect(hymn1?.number, 1);
      expect(hymn1?.title, isNotEmpty);
      expect(hymn1?.lyrics.stanzas, isNotEmpty);
      expect(hymn1?.lyrics.stanzas.first.text, isNotEmpty);
    });

    test('LanguagePack parses successfully from en.json (English)', () async {
      final jsonString =
          await rootBundle.loadString('assets/hymnal/languages/en.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      final pack = LanguagePack.fromJson(jsonMap);

      expect(pack.language, 'eng');
      expect(pack.hymns, isNotEmpty);

      final hymn1 = pack.hymns['hymn_0001'];
      expect(hymn1, isNotNull);
      expect(hymn1?.number, 1);
      expect(hymn1?.title, isNotEmpty);
    });
  });
}
