import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openbaptisthymnal/features/bible/data/bible_downloader.dart';
import 'package:openbaptisthymnal/features/bible/data/sources/local/bible_local_source.dart';
import 'package:openbaptisthymnal/features/bible/data/sources/local/installed_bible_store.dart';
import 'package:openbaptisthymnal/features/bible/data/sources/local/installed_bible_store_io.dart';
import 'package:openbaptisthymnal/features/bible/data/sources/remote/bible_catalog_source.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _catalogJson = {
  'schemaVersion': 1,
  'editions': [
    {
      'id': 'en-kjv',
      'name': 'English (KJV)',
      'abbreviation': 'KJV',
      'languageCode': 'en',
      'languageName': 'English',
      'sizeBytes': 100,
      'sha256': 'AB',
      'url': 'bibles/en-kjv-ab.zip',
      'attribution': 'Public Domain',
      'bundled': true,
    },
    {
      'id': 'xx-test',
      'name': 'Test (TST)',
      'abbreviation': 'TST',
      'languageCode': 'xx',
      'languageName': 'Testish',
      'sizeBytes': 100,
      'sha256': 'cd',
      'url': 'bibles/xx-test-cd.zip',
      'attribution': 'CC BY-SA 4.0',
    },
  ],
};

Uint8List _zip() {
  final manifest = {
    'edition': 'xx-test',
    'language': 'xx',
    'name': 'Test',
    'books': [
      {'ordinal': 1, 'code': 'JHN', 'name': 'John', 'chapters': [2]},
    ],
  };
  final a = Archive()
    ..addFile(ArchiveFile.bytes(
        'manifest.json', utf8.encode(json.encode(manifest))))
    ..addFile(ArchiveFile.bytes(
        'books/JHN.json',
        utf8.encode(json.encode({
          '1': {'1': 'In the beginning', '2': 'Same'}
        }))));
  return Uint8List.fromList(ZipEncoder().encode(a));
}

BibleCatalogEntry _entry(Uint8List zip, {String? sha}) => BibleCatalogEntry(
      id: 'xx-test',
      name: 'Test (TST)',
      abbreviation: 'TST',
      languageCode: 'xx',
      languageName: 'Testish',
      sizeBytes: zip.length,
      sha256: sha ?? sha256.convert(zip).toString(),
      url: 'bibles/xx-test-cd.zip',
      attribution: 'CC BY-SA 4.0',
      bundled: false,
    );

void main() {
  late Directory tmp;
  late FileInstalledBibleStore store;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('bibles_test');
    store = FileInstalledBibleStore(Directory('${tmp.path}/bibles'));
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  group('catalog', () {
    test('parses entries, lower-cases sha, defaults bundled to false', () {
      final c = BibleCatalog.fromJson(_catalogJson);
      expect(c.schemaVersion, 1);
      expect(c.editions.length, 2);
      expect(c.editions[0].bundled, isTrue);
      expect(c.editions[0].sha256, 'ab');
      expect(c.editions[1].bundled, isFalse);
      final e = c.editions[1].toEdition();
      expect(e.versionCode, 'tst');
      expect(e.attribution, 'CC BY-SA 4.0');
    });

    test('rejects a malformed catalog', () {
      expect(() => BibleCatalog.fromJson({'editions': []}),
          throwsFormatException);
      expect(
          () => BibleCatalog.fromJson({
                'schemaVersion': 1,
                'editions': [
                  {'id': 'x'}
                ]
              }),
          throwsA(anything));
    });

    test('fetch caches the catalog and cached() serves it offline', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      Uri? asked;
      final ok = BibleCatalogSource(
        MockClient((r) async {
          asked = r.url;
          return http.Response.bytes(utf8.encode(json.encode(_catalogJson)), 200);
        }),
        prefs,
        base: 'https://cdn.test/',
      );
      expect(ok.cached(), isNull);
      await ok.fetch();
      expect(asked.toString(), 'https://cdn.test/bibles/catalog.json');

      final offline = BibleCatalogSource(
        MockClient((r) async => throw http.ClientException('offline')),
        prefs,
      );
      await expectLater(offline.fetch(), throwsA(isA<http.ClientException>()));
      expect(offline.cached()!.editions.length, 2);
    });

    test('a bad body is not cached', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final src = BibleCatalogSource(
          MockClient((r) async => http.Response('{"nope":1}', 200)), prefs);
      await expectLater(src.fetch(), throwsA(anything));
      expect(src.cached(), isNull);
    });
  });

  group('download manager', () {
    BibleDownloader downloader(Uint8List body, {int status = 200}) =>
        BibleDownloader(
          MockClient.streaming((req, _) async {
            // Two chunks so progress has something to report.
            final half = body.length ~/ 2;
            return http.StreamedResponse(
              Stream.fromIterable(
                  [body.sublist(0, half), body.sublist(half)]),
              status,
              contentLength: body.length,
            );
          }),
          store,
        );

    test('reports progress, installs, and the reader source reads it',
        () async {
      final zip = _zip();
      final seen = <double>[];
      final edition =
          await downloader(zip).download(_entry(zip), onProgress: seen.add);
      expect(seen.first, closeTo(0.5, 0.01));
      expect(seen.last, 1);
      expect(seen, orderedEquals([...seen]..sort()));
      expect(edition.id, 'xx-test');

      expect((await store.list()).map((e) => e.id), ['xx-test']);
      final src = BibleLocalSource(installed: store);
      expect((await src.loadManifest('xx-test')).name, 'Test');
      final ch = await src.loadChapter('xx-test', 'JHN', 1);
      expect(ch.verses.first.text, 'In the beginning');
    });

    test('hash mismatch throws and leaves nothing behind', () async {
      final zip = _zip();
      await expectLater(
        downloader(zip).download(_entry(zip, sha: 'deadbeef')),
        throwsA(isA<BibleHashMismatch>()),
      );
      expect(await store.list(), isEmpty);
      expect(Directory('${tmp.path}/bibles').existsSync() &&
              Directory('${tmp.path}/bibles').listSync().isNotEmpty,
          isFalse);
    });

    test('HTTP failure throws ClientException', () async {
      final zip = _zip();
      await expectLater(downloader(zip, status: 404).download(_entry(zip)),
          throwsA(isA<http.ClientException>()));
    });

    test('install is atomic: a bad archive never appears as an edition',
        () async {
      final junk = Uint8List.fromList(utf8.encode('not a zip'));
      await expectLater(store.install(_entry(junk), junk), throwsA(anything));
      expect(await store.list(), isEmpty);
      expect(
          Directory('${tmp.path}/bibles')
              .listSync()
              .where((e) => e.path.contains('.tmp-')),
          isEmpty);
    });

    test('a half-finished temp folder is swept and ignored', () async {
      Directory('${tmp.path}/bibles/.tmp-xx-test/books')
          .createSync(recursive: true);
      expect(await store.list(), isEmpty);
      final zip = _zip();
      await store.install(_entry(zip), zip);
      expect((await store.list()).length, 1);
      expect(Directory('${tmp.path}/bibles/.tmp-xx-test').existsSync(),
          isFalse);
    });

    test('delete removes the edition', () async {
      final zip = _zip();
      await store.install(_entry(zip), zip);
      await store.delete('xx-test');
      expect(await store.list(), isEmpty);
      expect(await store.readString('xx-test', 'manifest.json'), isNull);
    });

    test('installed editions persist across a new store instance', () async {
      final zip = _zip();
      await store.install(_entry(zip), zip);
      final again = FileInstalledBibleStore(Directory('${tmp.path}/bibles'));
      expect((await again.list()).single.attribution, 'CC BY-SA 4.0');
    });
  });
}
