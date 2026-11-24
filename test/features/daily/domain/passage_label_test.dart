import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/bible/domain/verse_ref.dart';
import 'package:openbaptisthymnal/features/daily/domain/passage_label.dart';

void main() {
  List<VerseRange> refs(List<String> raw) =>
      [for (final r in raw) VerseRange.tryParse(r)!];

  const english = {'GEN': 'Genesis', 'PSA': 'Psalms', 'MAL': 'Malachi'};

  group('Given a plan day', () {
    group('When its passages are labelled', () {
      test('Then a multi-chapter passage reads as a chapter range', () {
        expect(formatPassages(refs(['GEN.1.1-4.26']), english), 'Genesis 1–4');
      });

      test('Then a single-chapter passage names just the chapter', () {
        // Verse numbers are an artifact of how the range is stored. Plan days
        // are always whole chapters, so "Psalms 120:1-7" would be technically
        // true and needlessly loud -- nobody says it that way.
        expect(formatPassages(refs(['PSA.120.1-7']), english), 'Psalms 120');
      });

      test('Then a day crossing a book boundary lists both books', () {
        expect(
          formatPassages(refs(['MAL.4.1-6', 'GEN.1.1-31']), english),
          'Malachi 4, Genesis 1',
        );
      });
    });

    group('When the reader is on a different translation', () {
      test('Then the book names follow that edition', () {
        // The plan stores only USFM codes, which is what lets one plan serve
        // every translation. The label is the only place the language enters.
        const yoruba = {'GEN': 'Jenesisi'};

        expect(formatPassages(refs(['GEN.1.1-4.26']), yoruba), 'Jenesisi 1–4');
      });
    });

    group('When a book code is missing from the edition', () {
      test('Then it falls back to the code instead of dropping the passage',
          () {
        // Ugly beats invisible: a card reading "GEN 1-4" is bad, but a card
        // that silently omits today's reading is broken.
        expect(formatPassages(refs(['GEN.1.1-4.26']), const {}), 'GEN 1–4');
      });
    });
  });
}
