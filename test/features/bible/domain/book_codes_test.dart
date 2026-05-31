import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/bible/domain/book_codes.dart';

void main() {
  test('there are exactly 66 unique book codes', () {
    expect(kBibleBookCodes.length, 66);
    expect(kBibleBookCodes.toSet().length, 66);
  });

  test('ordinal <-> code round-trips across the whole canon', () {
    for (var ordinal = 1; ordinal <= 66; ordinal++) {
      final code = bookCodeForOrdinal(ordinal);
      expect(code, isNotNull);
      expect(ordinalForBookCode(code!), ordinal);
    }
  });

  test('known anchors sit at the right ordinals', () {
    expect(bookCodeForOrdinal(1), 'GEN');
    expect(bookCodeForOrdinal(40), 'MAT');
    expect(bookCodeForOrdinal(43), 'JHN');
    expect(bookCodeForOrdinal(66), 'REV');
  });

  test('out-of-range ordinals and unknown codes return null', () {
    expect(bookCodeForOrdinal(0), isNull);
    expect(bookCodeForOrdinal(67), isNull);
    expect(ordinalForBookCode('ZZZ'), isNull);
  });

  test('testament split falls at Matthew', () {
    expect(isOldTestament(39), isTrue); // Malachi
    expect(isOldTestament(40), isFalse); // Matthew
  });
}
