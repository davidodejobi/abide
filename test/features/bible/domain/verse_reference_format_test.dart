import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/bible/domain/verse_reference_format.dart';

void main() {
  test('single verse', () {
    expect(formatVerseRange(3, [16]), '3:16');
  });

  test('contiguous run collapses to an en-dash range', () {
    expect(formatVerseRange(3, [16, 17, 18]), '3:16–18');
  });

  test('gaps split into comma-separated groups', () {
    expect(formatVerseRange(3, [16, 18]), '3:16, 18');
    expect(formatVerseRange(3, [16, 17, 19]), '3:16–17, 19');
  });

  test('unsorted and duplicate input is normalized', () {
    expect(formatVerseRange(3, [18, 16, 17, 16]), '3:16–18');
  });

  test('empty selection falls back to the chapter alone', () {
    expect(formatVerseRange(3, const []), '3');
  });
}
