import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/features/bible/data/bible_repository.dart';
import 'package:openbaptisthymnal/features/bible/data/sources/local/bible_local_source.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_chapter.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_edition.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';

final bibleLocalSourceProvider = Provider<BibleLocalSource>((ref) {
  return BibleLocalSource();
});

final bibleRepositoryProvider = Provider<BibleRepository>((ref) {
  return BibleRepository(ref.watch(bibleLocalSourceProvider));
});

/// All editions available to read and to use as a split companion.
final bibleEditionsProvider = Provider<List<BibleEdition>>((ref) {
  return ref.watch(bibleRepositoryProvider).editions();
});

/// The edition shown in the primary reading pane; defaults to English.
final primaryEditionProvider = StateProvider<String>((ref) => 'en-kjv');

/// Per-edition book/chapter index for the pickers.
final bibleManifestProvider =
    FutureProvider.family<BibleManifest, String>((ref, editionId) {
  return ref.watch(bibleRepositoryProvider).manifest(editionId);
});

/// Identifies one chapter request. A record gives value-equality for free, so
/// the family caches per (edition, book, chapter).
typedef ChapterQuery = ({String editionId, int ordinal, int chapter});

/// A single chapter of text for the given query.
final bibleChapterProvider =
    FutureProvider.family<BibleChapter, ChapterQuery>((ref, q) {
  return ref
      .watch(bibleRepositoryProvider)
      .chapter(q.editionId, q.ordinal, q.chapter);
});
