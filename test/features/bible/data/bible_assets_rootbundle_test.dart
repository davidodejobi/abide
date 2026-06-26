import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/bible/data/sources/local/bible_local_source.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_edition.dart';

// Loads through the DEFAULT rootBundle (not a disk shim), so this fails if the
// pubspec asset declarations for the editions are wrong — the same path the
// running app exercises.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final source = BibleLocalSource();

  // Every shipped edition must load through the real bundle with 66 books and a
  // non-empty John 3:16.
  for (final e in kBibleEditions) {
    test('rootBundle serves ${e.id} manifest + John 3:16', () async {
      final manifest = await source.loadManifest(e.id);
      expect(manifest.books.length, 66, reason: '${e.id} needs 66 books');
      final john3 = await source.loadChapter(e.id, 'JHN', 3);
      expect(john3.verses.firstWhere((v) => v.number == 16).text, isNotEmpty);
    });
  }

  test('English editions render John 3:16 about God', () async {
    for (final id in ['en-kjv', 'en-bsb', 'en-asv', 'en-ylt']) {
      final john3 = await source.loadChapter(id, 'JHN', 3);
      expect(john3.verses.firstWhere((v) => v.number == 16).text,
          contains('God'));
    }
  });

  test('every edition carries an attribution credit', () {
    for (final e in kBibleEditions) {
      expect(e.attribution, isNotEmpty, reason: '${e.id} must credit its source');
    }
    // The Biblica editions are CC BY-SA; the credit must name the license.
    for (final id in ['ha-biblica', 'ig-biblica', 'yo-biblica']) {
      final e = kBibleEditions.firstWhere((x) => x.id == id);
      expect(e.attribution, contains('CC BY-SA'));
    }
  });
}
