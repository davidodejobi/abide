import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/bible/domain/verse_ref.dart';

void main() {
  test('parses a well-formed ref and round-trips through toString', () {
    final ref = VerseRef.tryParse('JHN.3.16');
    expect(ref, isNotNull);
    expect(ref!.book, 'JHN');
    expect(ref.chapter, 3);
    expect(ref.verse, 16);
    expect(ref.toString(), 'JHN.3.16');
    expect(ref.ordinal, 43);
  });

  test('upper-cases the book code', () {
    expect(VerseRef.tryParse('jhn.3.16')!.book, 'JHN');
  });

  test('rejects unknown book codes', () {
    expect(VerseRef.tryParse('ZZZ.1.1'), isNull);
  });

  test('rejects malformed or non-positive refs', () {
    expect(VerseRef.tryParse('JHN.3'), isNull);
    expect(VerseRef.tryParse('JHN.3.16.1'), isNull);
    expect(VerseRef.tryParse('JHN.x.1'), isNull);
    expect(VerseRef.tryParse('JHN.0.1'), isNull);
    expect(VerseRef.tryParse('JHN.3.0'), isNull);
    expect(VerseRef.tryParse(''), isNull);
  });

  test('value equality and hashing', () {
    expect(const VerseRef('JHN', 3, 16), const VerseRef('JHN', 3, 16));
    expect(
      const VerseRef('JHN', 3, 16).hashCode,
      const VerseRef('JHN', 3, 16).hashCode,
    );
    expect(const VerseRef('JHN', 3, 16), isNot(const VerseRef('JHN', 3, 17)));
  });
}
