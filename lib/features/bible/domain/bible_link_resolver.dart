import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/preferences/linking_preferences.dart';
import 'package:openbaptisthymnal/features/bible/domain/verse_ref.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_edition.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';
import 'package:openbaptisthymnal/features/hymn/providers/hymnal_provider.dart';

/// Where a tablet `[[bible:...]]` link should open: an edition + chapter to
/// navigate to, an optional verse range to highlight, and an optional toast
/// the chapter view should surface when something degraded (e.g. an unknown
/// edition pin or a verse number missing from the chosen edition).
class BibleNavigationTarget {
  const BibleNavigationTarget({
    required this.editionId,
    required this.ordinal,
    required this.chapter,
    this.highlightFromVerse,
    this.highlightToVerse,
    this.toastMessage,
  });

  final String editionId;
  final int ordinal;
  final int chapter;
  final int? highlightFromVerse;
  final int? highlightToVerse;
  final String? toastMessage;
}

/// Resolves a `[[bible:...]]` link's `targetKey` (plus optional `editionPin`)
/// to a concrete navigation target. The verse-range syntax is accepted but
/// missing-verse degradation only surfaces a toast — the link still opens the
/// chapter so the user never lands on a dead end.
///
/// We intentionally default to English KJV when no user preference or reading
/// position is set, matching the hymn link resolver — tablet links should be
/// portable: a verse quoted today opens in the most widely understood edition
/// tomorrow.
class BibleLinkResolver {
  BibleLinkResolver(this._ref);

  final Ref _ref;

  /// Resolves [targetKey] (e.g. `JHN.3.16` or `JHN.3.16-18`).
  /// If [editionPin] is provided and that edition exists, it wins outright;
  /// otherwise we walk the priority list below and surface a soft hint when
  /// the requested pin isn't installed.
  ///
  /// Priority for unpinned (or missing-pin) links:
  ///   1. user's default-bible-edition setting
  ///   2. the user's current reading position edition
  ///   3. the first edition whose languageCode matches the app language
  ///   4. the first installed edition
  Future<BibleNavigationTarget?> resolve(
    String targetKey, {
    String? editionPin,
  }) async {
    final range = VerseRange.tryParse(targetKey);
    if (range == null) return null;
    final start = range.start;
    final ordinal = start.ordinal;
    if (ordinal == null) return null;

    final editions = _ref.read(bibleEditionsProvider);
    if (editions.isEmpty) return null;

    final pinned = _findEdition(editions, editionPin);
    String? toast;
    BibleEdition chosen;
    if (editionPin != null && pinned == null) {
      toast = 'That edition ($editionPin) isn\'t installed yet. '
          'Showing your current Bible instead.';
      chosen = _pickFallbackEdition(editions);
    } else {
      chosen = pinned ?? _pickFallbackEdition(editions);
    }

    // Best-effort verse-presence check. Manifest load failures are non-fatal:
    // we still open the link, just without verse-miss messaging.
    int? hiFrom = start.verse;
    int? hiTo = range.end.verse;
    int chapter = start.chapter;
    try {
      final manifest = await _ref.read(bibleManifestProvider(chosen.id).future);
      final book = _findBook(manifest, ordinal);
      if (book == null) {
        toast ??= '${start.book} isn\'t in ${chosen.displayName} yet. '
            'Showing the closest available chapter.';
        chapter = 1;
      } else if (chapter > book.chapterCount) {
        toast ??= 'Chapter $chapter of ${book.name} isn\'t in '
            '${chosen.displayName}. Showing chapter ${book.chapterCount}.';
        chapter = book.chapterCount;
        hiFrom = null;
        hiTo = null;
      } else {
        final verseCount = book.chapterVerseCounts[chapter - 1];
        if (hiFrom > verseCount) {
          toast ??= 'Verse $hiFrom isn\'t in ${chosen.displayName} '
              '${book.name} $chapter. Showing the chapter.';
          hiFrom = null;
          hiTo = null;
        } else if (hiTo > verseCount) {
          // Clamp the range end to the last verse this edition actually has.
          hiTo = verseCount;
        }
      }
    } catch (_) {
      // Manifest unavailable; let the chapter loader surface its own error.
    }

    return BibleNavigationTarget(
      editionId: chosen.id,
      ordinal: ordinal,
      chapter: chapter,
      highlightFromVerse: hiFrom,
      highlightToVerse: hiTo,
      toastMessage: toast,
    );
  }

  BibleEdition? _findEdition(List<BibleEdition> editions, String? id) {
    if (id == null) return null;
    for (final e in editions) {
      if (e.id.toLowerCase() == id.toLowerCase()) return e;
    }
    return null;
  }

  BibleBookInfo? _findBook(BibleManifest manifest, int ordinal) {
    for (final b in manifest.books) {
      if (b.ordinal == ordinal) return b;
    }
    return null;
  }

  /// The edition we open unpinned Bible links in when no preference or reading
  /// position is set. English KJV is the most widely understood shipped edition.
  static const _bibleLinkDefault = 'en-kjv';

  BibleEdition _pickFallbackEdition(List<BibleEdition> editions) {
    final prefs = _ref.read(linkingPreferencesProvider);
    final defaultId = prefs.defaultBibleEditionId;
    final defaulted = _findEdition(editions, defaultId);
    if (defaulted != null) return defaulted;

    final readingId = _ref.read(primaryEditionProvider);
    final reading = _findEdition(editions, readingId);
    if (reading != null) return reading;

    // When the user has no explicit preference and no current reading
    // position, English wins over the app language. Tablet links should
    // be portable: a verse quoted today should open in the most widely
    // understood edition tomorrow.
    final englishMatch = _findEdition(editions, _bibleLinkDefault);
    if (englishMatch != null) return englishMatch;

    final language = _ref.read(languageProvider);
    for (final e in editions) {
      if (e.languageCode == language) return e;
    }
    return editions.first;
  }
}

final bibleLinkResolverProvider = Provider<BibleLinkResolver>((ref) {
  return BibleLinkResolver(ref);
});
