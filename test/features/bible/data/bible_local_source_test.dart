import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/bible/data/bible_repository.dart';
import 'package:openbaptisthymnal/features/bible/data/sources/local/bible_local_source.dart';

/// Reads asset keys straight off disk so the source is exercised against the
/// real generated `assets/bible/**` files (tests run from the project root).
class _DiskBundle extends AssetBundle {
  @override
  Future<ByteData> load(String key) => throw UnimplementedError();

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      File(key).readAsString();
}

void main() {
  late BibleLocalSource source;
  late BibleRepository repo;

  setUp(() {
    source = BibleLocalSource(bundle: _DiskBundle());
    repo = BibleRepository(source);
  });

  test('manifest lists all 66 books with John at ordinal 43', () async {
    final manifest = await source.loadManifest('en-kjv');
    expect(manifest.edition, 'en-kjv');
    expect(manifest.books.length, 66);
    final john = manifest.books[42];
    expect(john.ordinal, 43);
    expect(john.code, 'JHN');
    expect(john.name, 'John');
    expect(john.chapterCount, 21);
  });

  test('loads a chapter with verses in canonical order', () async {
    final chapter = await source.loadChapter('en-kjv', 'JHN', 3);
    expect(chapter.book, 'JHN');
    expect(chapter.chapter, 3);
    expect(chapter.verses, isNotEmpty);

    final numbers = chapter.verses.map((v) => v.number).toList();
    final sorted = [...numbers]..sort();
    expect(numbers, sorted, reason: 'verses must be in ascending order');

    final v16 = chapter.verses.firstWhere((v) => v.number == 16);
    expect(v16.text, contains('For God so loved the world'));
    expect(v16.ref.toString(), 'JHN.3.16');
  });

  test('Yoruba edition aligns by code with a localized book name', () async {
    final manifest = await source.loadManifest('yo-bmy');
    final john = manifest.books[42];
    expect(john.code, 'JHN'); // same canonical code
    expect(john.name, isNot('John')); // localized display name
  });

  test('repository exposes editions and lookup by id', () {
    expect(repo.editions().map((e) => e.id), containsAll(['en-kjv', 'yo-bmy']));
    expect(repo.editionById('yo-bmy')!.languageCode, 'yo');
    expect(repo.editionById('nope'), isNull);
  });

  test('bundled public-domain English editions load with 66 books', () async {
    for (final id in ['en-bsb', 'en-asv', 'en-ylt']) {
      final manifest = await source.loadManifest(id);
      expect(manifest.books.length, 66, reason: '$id should have 66 books');
      expect(manifest.books[42].code, 'JHN', reason: '$id book 43 is John');

      final john3 = await source.loadChapter(id, 'JHN', 3);
      final v16 = john3.verses.firstWhere((v) => v.number == 16);
      expect(v16.text, contains('God'),
          reason: '$id John 3:16 should mention God');
      expect(v16.ref.toString(), 'JHN.3.16');
    }
  });

  test('the same edition reads distinct text across translations', () async {
    final kjv = await source.loadChapter('en-kjv', 'JHN', 3);
    final ylt = await source.loadChapter('en-ylt', 'JHN', 3);
    final kjv16 = kjv.verses.firstWhere((v) => v.number == 16).text;
    final ylt16 = ylt.verses.firstWhere((v) => v.number == 16).text;
    expect(kjv16, isNot(ylt16),
        reason: 'KJV and YLT John 3:16 wording must differ');
  });
}
