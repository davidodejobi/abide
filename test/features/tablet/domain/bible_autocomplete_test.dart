import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';
import 'package:openbaptisthymnal/features/tablet/domain/bible_autocomplete.dart';

/// A minimal manifest that looks like the real English KJV edition but only
/// contains the books our tests need (Genesis, John, Revelation, Psalms).
BibleManifest _testManifest() => BibleManifest(
      edition: 'en-kjv',
      language: 'eng',
      name: 'English (KJV)',
      books: [
        BibleBookInfo(
          ordinal: 1,
          code: 'GEN',
          name: 'Genesis',
          chapterVerseCounts: [
            for (var i = 0; i < 50; i++) 31, // 50 chapters, 31 verses each
          ],
        ),
        const BibleBookInfo(
          ordinal: 43,
          code: 'JHN',
          name: 'John',
          chapterVerseCounts: [
            51, // ch 1
            25, // ch 2
            36, // ch 3
            54, // ch 4
            47, // ch 5
            71, // ch 6
            53, // ch 7
            59, // ch 8
            41, // ch 9
            42, // ch 10
            57, // ch 11
            50, // ch 12
            38, // ch 13
            31, // ch 14
            27, // ch 15
            33, // ch 16
            26, // ch 17
            40, // ch 18
            42, // ch 19
            31, // ch 20
            25, // ch 21
          ],
        ),
        BibleBookInfo(
          ordinal: 66,
          code: 'REV',
          name: 'Revelation',
          chapterVerseCounts: List.generate(22, (_) => 20),
        ),
        BibleBookInfo(
          ordinal: 19,
          code: 'PSA',
          name: 'Psalms',
          chapterVerseCounts: List.generate(150, (_) => 6),
        ),
      ],
    );

void main() {
  final manifest = _testManifest();

  group('bibleAutocompleteSuggestions – empty query', () {
    test('returns 5 books when nothing typed after bible:', () {
      final result = bibleAutocompleteSuggestions(manifest, 'bible:');
      expect(result.length, 4); // our test manifest has 4 books
      expect(result.first.token, 'bible:GEN');
      expect(result.first.label, 'Genesis (GEN)');
    });
  });

  group('bibleAutocompleteSuggestions – book search', () {
    test('matches by book code prefix', () {
      final result = bibleAutocompleteSuggestions(manifest, 'bible:j');
      expect(result.length, 1);
      expect(result.first.token, 'bible:JHN');
      expect(result.first.label, 'John (JHN)');
    });

    test('matches by book name prefix (exact match shows chapters)', () {
      final result = bibleAutocompleteSuggestions(manifest, 'bible:gen');
      expect(result.length, 50); // Genesis has 50 chapters
      expect(result.first.token, 'bible:GEN.1');
    });

    test('matches by full book code (exact match shows chapters)', () {
      final result = bibleAutocompleteSuggestions(manifest, 'bible:PSA');
      expect(result.length, 150); // Psalms has 150 chapters
      expect(result.first.token, 'bible:PSA.1');
    });

    test('returns nothing for gibberish', () {
      final result = bibleAutocompleteSuggestions(manifest, 'bible:xyzzy');
      expect(result, isEmpty);
    });
  });

  group('bibleAutocompleteSuggestions – chapters', () {
    test('exact book returns all chapters', () {
      final result = bibleAutocompleteSuggestions(manifest, 'bible:JHN');
      expect(result.length, 21); // John has 21 chapters
      expect(result.first.token, 'bible:JHN.1');
      expect(result.first.label, 'John 1');
      expect(result.first.isChapter, isTrue);
      expect(result.last.token, 'bible:JHN.21');
    });

    test('Genesis has 50 chapters', () {
      final result = bibleAutocompleteSuggestions(manifest, 'bible:GEN');
      expect(result.length, 50);
      expect(result.first.label, 'Genesis 1');
      expect(result.last.label, 'Genesis 50');
    });
  });

  group('bibleAutocompleteSuggestions – chapter selection', () {
    test('exact chapter returns single suggestion', () {
      final result = bibleAutocompleteSuggestions(manifest, 'bible:JHN.3');
      expect(result.length, 1);
      expect(result.first.token, 'bible:JHN.3');
      expect(result.first.label, 'John 3');
      expect(result.first.isChapter, isTrue);
    });

    test('exact chapter with verse dot returns single suggestion', () {
      final result = bibleAutocompleteSuggestions(manifest, 'bible:GEN.3');
      expect(result.length, 1);
      expect(result.first.token, 'bible:GEN.3');
      expect(result.first.label, 'Genesis 3');
      expect(result.first.isChapter, isTrue);
    });

    test('out of range chapter returns empty', () {
      final result = bibleAutocompleteSuggestions(manifest, 'bible:JHN.99');
      expect(result, isEmpty);
    });

    test('chapter 0 returns empty', () {
      final result = bibleAutocompleteSuggestions(manifest, 'bible:JHN.0');
      expect(result, isEmpty);
    });
  });

  group('bibleAutocompleteSuggestions – verse selection', () {
    test('exact verse returns single suggestion', () {
      final result = bibleAutocompleteSuggestions(manifest, 'bible:JHN.3.16');
      expect(result.length, 1);
      expect(result.first.token, 'bible:JHN.3.16');
      expect(result.first.label, 'John 3:16');
      expect(result.first.isVerse, isTrue);
    });

    test('Revelation 20:5 is valid', () {
      final result = bibleAutocompleteSuggestions(manifest, 'bible:REV.20.5');
      expect(result.length, 1);
      expect(result.first.token, 'bible:REV.20.5');
      expect(result.first.isVerse, isTrue);
    });

    test('out of range verse returns empty', () {
      final result = bibleAutocompleteSuggestions(manifest, 'bible:JHN.3.999');
      expect(result, isEmpty);
    });

    test('non-numeric verse returns empty', () {
      final result = bibleAutocompleteSuggestions(manifest, 'bible:JHN.3.abc');
      expect(result, isEmpty);
    });
  });

  group('bibleAutocompleteSuggestions – edge cases', () {
    test('non-bible query returns empty', () {
      expect(bibleAutocompleteSuggestions(manifest, 'hymn:'), isEmpty);
      expect(bibleAutocompleteSuggestions(manifest, 'hello'), isEmpty);
      expect(bibleAutocompleteSuggestions(manifest, ''), isEmpty);
    });

    test('non-existent book returns empty', () {
      final result = bibleAutocompleteSuggestions(manifest, 'bible:TOB.1');
      expect(result, isEmpty);
    });

    test('bible: prefix must be lowercase', () {
      final result = bibleAutocompleteSuggestions(manifest, 'Bible:GEN');
      expect(result, isEmpty);
    });
  });
}
