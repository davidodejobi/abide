import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/bible/data/sources/local/bible_local_source.dart';

// Loads through the DEFAULT rootBundle (not a disk shim), so this fails if the
// pubspec asset declarations for the new editions are wrong — the same path the
// running app exercises.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final source = BibleLocalSource();

  for (final id in ['en-kjv', 'en-bsb', 'en-asv', 'en-ylt']) {
    test('rootBundle serves $id manifest + John 3', () async {
      final manifest = await source.loadManifest(id);
      expect(manifest.books.length, 66);
      final john3 = await source.loadChapter(id, 'JHN', 3);
      expect(john3.verses.firstWhere((v) => v.number == 16).text, contains('God'));
    });
  }
}
