import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_baptist_hymnal/data/models/hymnal_core.dart';
import 'package:open_baptist_hymnal/data/models/hymnal_index.dart';
import 'package:open_baptist_hymnal/data/models/language_pack.dart';

void main() {
  group('Hymnal Data Models Test', () {
    setUp(() {
      WidgetsFlutterBinding.ensureInitialized();
    });

    test('HymnalCore parses successfully from core.json', () async {
      final jsonString = await rootBundle.loadString('assets/hymnal/core.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      final core = HymnalCore.fromJson(jsonMap);

      expect(core.schemaVersion, '1.0.0');
      expect(core.hymnalId, 'onitebomi_2000');
      expect(core.hymns.length, 5);
      expect(core.hymns['hymn_0001']?.category, 'praise');
    });

    test('HymnalIndex parses successfully from index.json', () async {
      final jsonString =
          await rootBundle.loadString('assets/hymnal/index.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      final index = HymnalIndex.fromJson(jsonMap);

      expect(index.orders.length, 2);
      expect(index.orders['yor']?.length, 5);
      expect(index.orders['eng']?.length, 3);
      expect(index.orders['yor']?[0], 'hymn_0001');
      expect(index.orders['eng']?[0], 'hymn_0003');
    });

    test('LanguagePack parses successfully from yo.json (Yoruba)', () async {
      final jsonString =
          await rootBundle.loadString('assets/hymnal/languages/yo.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      final pack = LanguagePack.fromJson(jsonMap);

      expect(pack.language, 'yor');
      expect(pack.hymnalName, 'Iwe Orin Ijo Onitebomi');
      expect(pack.hymns.length, 5);

      final hymn1 = pack.hymns['hymn_0001'];
      expect(hymn1?.number, 1);
      expect(hymn1?.title, 'E Fi Iyin Fun Olorun');
      expect(hymn1?.lyrics.stanzas.length, 1);
      expect(hymn1?.lyrics.stanzas[0].text, contains('E fi iyin'));
    });

    test('LanguagePack parses successfully from en.json (English)', () async {
      final jsonString =
          await rootBundle.loadString('assets/hymnal/languages/en.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      final pack = LanguagePack.fromJson(jsonMap);

      expect(pack.language, 'eng');
      expect(pack.hymnalName, 'Baptist Hymnal');
      expect(pack.hymns.length, 3);

      final hymn1 = pack.hymns['hymn_0001'];
      expect(hymn1?.number, 120);
      expect(hymn1?.title, 'Give Glory to God');
    });
  });
}
