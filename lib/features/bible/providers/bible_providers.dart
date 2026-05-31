import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/features/bible/data/bible_repository.dart';
import 'package:openbaptisthymnal/features/bible/data/sources/local/bible_local_source.dart';
import 'package:openbaptisthymnal/features/bible/data/sources/local/bible_reading_position_source.dart';
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

final bibleReadingPositionSourceProvider =
    Provider<BibleReadingPositionSource>((ref) {
  return BibleReadingPositionSource(ref.watch(sharedPreferencesProvider));
});

/// Where the reader is: edition + book + chapter, persisted across launches.
/// This is the single source of truth for the primary reading pane.
final bibleReadingPositionProvider =
    NotifierProvider<BibleReadingPositionNotifier, ReadingPosition>(
  BibleReadingPositionNotifier.new,
);

class BibleReadingPositionNotifier extends Notifier<ReadingPosition> {
  static const _default =
      ReadingPosition(editionId: 'en-kjv', ordinal: 43, chapter: 1);

  @override
  ReadingPosition build() {
    return ref.read(bibleReadingPositionSourceProvider).read() ?? _default;
  }

  void _set(ReadingPosition next) {
    state = next;
    ref.read(bibleReadingPositionSourceProvider).write(next);
  }

  /// Jumps to a chapter within the current edition, resetting nothing else.
  void openChapter(int ordinal, int chapter) =>
      _set(state.copyWith(ordinal: ordinal, chapter: chapter));

  /// Switches the primary edition, keeping the same book/chapter so the reader
  /// stays put when toggling translations.
  void setEdition(String editionId) =>
      _set(state.copyWith(editionId: editionId));
}

/// Convenience read of just the primary edition id.
final primaryEditionProvider = Provider<String>((ref) {
  return ref.watch(bibleReadingPositionProvider).editionId;
});

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
