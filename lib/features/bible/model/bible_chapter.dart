import 'package:openbaptisthymnal/features/bible/domain/verse_ref.dart';

/// A single verse with its canonical ref. [ref] is the alignment/join key.
class Verse {
  const Verse({required this.ref, required this.text});

  final VerseRef ref;
  final String text;

  int get number => ref.verse;
}

/// One chapter of one edition: an ordered list of the verses present in the
/// source (gaps in the source simply don't appear).
class BibleChapter {
  const BibleChapter({
    required this.book,
    required this.chapter,
    required this.verses,
  });

  /// Canonical book code, e.g. `JHN`.
  final String book;
  final int chapter;
  final List<Verse> verses;
}
