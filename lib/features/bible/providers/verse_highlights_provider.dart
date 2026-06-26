import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/database_provider.dart';
import 'package:openbaptisthymnal/features/bible/domain/verse_ref.dart';

/// Verse number -> its highlight annotation for one chapter. Edition-independent:
/// keyed only on the canonical verse, so the same map drives every translation
/// in both reader panes.
typedef VerseHighlights = Map<int, BibleAnnotation>;

final verseHighlightsProvider = StreamProvider.family<VerseHighlights,
    ({String bookCode, int chapter})>((ref, q) async* {
  final dao = ref.watch(bibleAnnotationsDaoProvider);
  await for (final anns in dao.watchAnnotationsForChapter(q.bookCode, q.chapter)) {
    final byVerse = <int, BibleAnnotation>{};
    for (final a in anns) {
      final r = VerseRef.tryParse(a.verseRef);
      if (r == null || r.book != q.bookCode || r.chapter != q.chapter) continue;
      byVerse[r.verse] = a;
    }
    yield byVerse;
  }
});
