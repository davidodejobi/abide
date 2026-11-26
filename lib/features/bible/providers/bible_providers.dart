import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/features/bible/data/bible_repository.dart';
import 'package:openbaptisthymnal/features/bible/data/sources/local/bible_local_source.dart';
import 'package:openbaptisthymnal/features/bible/data/sources/local/installed_bible_store.dart';
import 'package:openbaptisthymnal/features/bible/data/sources/local/bible_reading_position_source.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_chapter.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_edition.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';

/// Where downloaded editions live. main() overrides this with the real store;
/// the default (tests, web) has nothing installed.
final installedBibleStoreProvider = Provider<InstalledBibleStore>(
  (ref) => const NoopInstalledBibleStore(),
);

/// Editions found on disk at launch, read in main() so the reader never starts
/// on a saved edition it has not yet discovered.
final initialInstalledBiblesProvider =
    Provider<List<BibleEdition>>((ref) => const []);

/// Downloaded editions, live. Changes when one is installed or removed.
final installedBiblesProvider =
    NotifierProvider<InstalledBiblesNotifier, List<BibleEdition>>(
  InstalledBiblesNotifier.new,
);

class InstalledBiblesNotifier extends Notifier<List<BibleEdition>> {
  @override
  List<BibleEdition> build() => ref.read(initialInstalledBiblesProvider);

  void add(BibleEdition e) =>
      state = [for (final x in state) if (x.id != e.id) x, e];

  void remove(String id) => state = [
        for (final x in state)
          if (x.id != id) x,
      ];
}

final bibleLocalSourceProvider = Provider<BibleLocalSource>((ref) {
  return BibleLocalSource(installed: ref.watch(installedBibleStoreProvider));
});

final bibleRepositoryProvider = Provider<BibleRepository>((ref) {
  return BibleRepository(
    ref.watch(bibleLocalSourceProvider),
    editionsOf: () => ref.read(bibleEditionsProvider),
  );
});

/// All editions available to read and to use as a split companion: the
/// bundled ones, then the downloaded ones.
final bibleEditionsProvider = Provider<List<BibleEdition>>((ref) {
  return [...kBibleEditions, ...ref.watch(installedBiblesProvider)];
});

/// The edition the reader falls back to when a saved one is not on the phone.
const kFallbackEditionId = 'en-kjv';

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
      ReadingPosition(editionId: 'en-kjv', bookCode: 'JHN', chapter: 1);

  @override
  ReadingPosition build() {
    final saved =
        ref.read(bibleReadingPositionSourceProvider).read() ?? _default;
    // A saved edition that is no longer on the phone (removed, or never
    // downloaded on this device) reads as the fallback. The saved value is
    // left alone, so re-downloading it brings the reader back.
    final available =
        ref.watch(bibleEditionsProvider).any((e) => e.id == saved.editionId);
    return available ? saved : saved.copyWith(editionId: kFallbackEditionId);
  }

  void _set(ReadingPosition next) {
    state = next;
    ref.read(bibleReadingPositionSourceProvider).write(next);
  }

  /// Jumps to a chapter within the current edition, resetting nothing else.
  void openChapter(String bookCode, int chapter) =>
      _set(state.copyWith(bookCode: bookCode, chapter: chapter));

  /// Switches the primary edition, keeping the same book/chapter so the reader
  /// stays put when toggling translations.
  void setEdition(String editionId) =>
      _set(state.copyWith(editionId: editionId));
}

/// Id of the saved edition when it is not available, else null. Drives the
/// gentle "download it" prompt in the reader.
final missingSavedEditionProvider = Provider<String?>((ref) {
  ref.watch(bibleReadingPositionProvider); // re-check after the user picks one
  final saved = ref.watch(bibleReadingPositionSourceProvider).read()?.editionId;
  final have = ref.watch(bibleEditionsProvider).any((e) => e.id == saved);
  return saved == null || have ? null : saved;
});

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
typedef ChapterQuery = ({String editionId, String bookCode, int chapter});

/// A single chapter of text for the given query.
final bibleChapterProvider =
    FutureProvider.family<BibleChapter, ChapterQuery>((ref, q) {
  return ref
      .watch(bibleRepositoryProvider)
      .chapter(q.editionId, q.bookCode, q.chapter);
});
