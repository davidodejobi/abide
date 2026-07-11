import 'package:openbaptisthymnal/features/bible/domain/verse_ref.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';

import 'reading_plan.dart';

/// Builds a reading plan that hands out **whole chapters**, balanced by **verse
/// count**.
///
/// Two separate decisions, and both matter:
///
/// *Balanced by verses, not chapters.* Psalm 119 runs to 176 verses; Psalm 117
/// has 2. A plan that promises "3 chapters a day" quietly means twenty minutes
/// one day and ninety seconds the next, and that is how people quit somewhere
/// in Leviticus. The manifest already carries a verse count per chapter, so
/// weighting by it costs nothing and buys a steady day.
///
/// *Whole chapters, never part of one.* Verses are the weight; the chapter is
/// the unit. Splitting mid-chapter would mean a plan day pointing at a specific
/// verse number -- and verse numbering is not stable across translations, so the
/// same day would land in different places in KJV and Yoruba. Handing out whole
/// chapters means the reader opens the chapter and the versification question
/// never arises.
List<PlanDay> generateVerseBalancedDays({
  required List<BibleBookInfo> books,
  required int days,
}) {
  if (days < 1) {
    throw ArgumentError.value(days, 'days', 'must be at least 1');
  }

  final chapters = [
    for (final book in books)
      for (var i = 0; i < book.chapterVerseCounts.length; i++)
        _Chapter(book.code, i + 1, book.chapterVerseCounts[i]),
  ];

  if (chapters.length < days) {
    throw ArgumentError.value(
      days,
      'days',
      'only ${chapters.length} chapters for $days days -- some day would be '
          'empty',
    );
  }

  final totalVerses = chapters.fold<int>(0, (sum, c) => sum + c.verseCount);

  final result = <PlanDay>[];
  var next = 0; // index of the first unassigned chapter
  var versesSoFar = 0;

  for (var day = 1; day <= days; day++) {
    // Where the reader *should* be by the end of this day. A cumulative target
    // rather than a fixed per-day quota, so the rounding error left by one
    // oversized chapter is absorbed by the next day instead of compounding
    // across 365 of them.
    final target = totalVerses * day / days;

    final assigned = <_Chapter>[];
    do {
      final chapter = chapters[next++];
      assigned.add(chapter);
      versesSoFar += chapter.verseCount;
    } while (versesSoFar < target &&
        // Never eat into the chapters the remaining days still need. This is
        // what guarantees every day gets at least one chapter, and that the
        // final day lands exactly on the last one.
        chapters.length - next > days - day);

    result.add(
      PlanDay(dayIndex: day, passages: _mergeToRanges(assigned)),
    );
  }

  assert(next == chapters.length, 'every chapter must be assigned');
  return result;
}

/// Collapses a day's chapters into as few [VerseRange]s as possible.
///
/// Consecutive chapters of the same book become one range (`GEN.1.1-3.24`). A
/// book boundary forces a new range: [VerseRange] is defined as a span *within*
/// a book and rejects one that crosses out of it.
List<VerseRange> _mergeToRanges(List<_Chapter> chapters) {
  final ranges = <VerseRange>[];
  var i = 0;

  while (i < chapters.length) {
    final first = chapters[i];
    var last = first;

    var j = i + 1;
    while (j < chapters.length &&
        chapters[j].book == last.book &&
        chapters[j].number == last.number + 1) {
      last = chapters[j];
      j++;
    }

    ranges.add(
      VerseRange(
        VerseRef(first.book, first.number, 1),
        VerseRef(last.book, last.number, last.verseCount),
      ),
    );
    i = j;
  }

  return List.unmodifiable(ranges);
}

class _Chapter {
  const _Chapter(this.book, this.number, this.verseCount);

  final String book;
  final int number;
  final int verseCount;
}
