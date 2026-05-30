import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/tablet/domain/link_autocomplete.dart';

void main() {
  group('linkAutocompleteQuery', () {
    test('returns null when no open token', () {
      expect(linkAutocompleteQuery('hello', 5), isNull);
      expect(linkAutocompleteQuery('', 0), isNull);
    });

    test('returns empty query right after [[', () {
      expect(linkAutocompleteQuery('see [[', 6), '');
    });

    test('returns the typed query', () {
      expect(linkAutocompleteQuery('see [[Gra', 9), 'Gra');
    });

    test('returns null once the token is closed', () {
      expect(linkAutocompleteQuery('see [[Grace]]', 13), isNull);
    });

    test('returns null across a newline', () {
      expect(linkAutocompleteQuery('[[Gra\nce', 8), isNull);
    });

    test('uses the nearest open token', () {
      expect(linkAutocompleteQuery('[[a]] then [[b', 14), 'b');
    });

    test('query stops at the cursor, not end of text', () {
      expect(linkAutocompleteQuery('[[Grace and more', 5), 'Gra');
    });
  });

  group('applyLinkCompletion', () {
    test('replaces the active fragment with a closed token', () {
      final r = applyLinkCompletion('see [[Gra', 9, 'Grace');
      expect(r.text, 'see [[Grace]]');
      expect(r.cursor, r.text.length);
    });

    test('keeps text after the cursor intact', () {
      final r = applyLinkCompletion('a [[hy and b', 6, 'hymn:hymn_0001');
      expect(r.text, 'a [[hymn:hymn_0001]] and b');
      expect(r.cursor, 'a [[hymn:hymn_0001]]'.length);
    });

    test('completes an empty fragment', () {
      final r = applyLinkCompletion('see [[', 6, 'Grace');
      expect(r.text, 'see [[Grace]]');
    });
  });
}
