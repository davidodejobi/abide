import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/note_links_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/database_provider.dart';
import 'package:openbaptisthymnal/features/bible/domain/verse_ref.dart';

/// Verse number -> tablets that link to it. Built per chapter from the
/// book-level backlink stream, expanding any verse ranges that overlap the
/// chapter. De-duped by note id so a tablet that references a verse twice still
/// shows once.
typedef VerseBacklinks = Map<int, List<BibleBacklink>>;

/// Backlinks for one chapter, keyed by (bookCode, chapter). Rebuilds whenever a
/// tablet that touches this book is saved or deleted.
final verseBacklinksProvider = StreamProvider.family<VerseBacklinks,
    ({String bookCode, int chapter})>((ref, q) async* {
  final dao = ref.watch(noteLinksDaoProvider);
  await for (final links in dao.watchBibleBacklinksForBook(q.bookCode)) {
    final byVerse = <int, List<BibleBacklink>>{};
    final seenPerVerse = <int, Set<String>>{};
    for (final link in links) {
      final range = VerseRange.tryParse(link.targetKey);
      if (range == null || range.start.book != q.bookCode) continue;
      // Skip ranges that don't touch this chapter at all.
      if (range.start.chapter > q.chapter || range.end.chapter < q.chapter) {
        continue;
      }
      final from = range.start.chapter == q.chapter ? range.start.verse : 1;
      final to = range.end.chapter == q.chapter ? range.end.verse : 1000;
      for (var v = from; v <= to; v++) {
        final seen = seenPerVerse.putIfAbsent(v, () => <String>{});
        if (!seen.add(link.noteId)) continue;
        byVerse.putIfAbsent(v, () => []).add(link);
      }
    }
    yield byVerse;
  }
});
