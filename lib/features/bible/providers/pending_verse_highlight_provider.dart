import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A single-use request to highlight a verse (or verse range) the next time a
/// chapter view mounts. The tablet tap handler sets this just before pushing
/// the Bible tab; the chapter view reads and clears it on first build so a
/// second navigation doesn't re-flash an old highlight.
class PendingVerseHighlight {
  const PendingVerseHighlight({
    required this.editionId,
    required this.ordinal,
    required this.chapter,
    required this.fromVerse,
    required this.toVerse,
  });

  final String editionId;
  final int ordinal;
  final int chapter;
  final int fromVerse;
  final int toVerse;

  bool matches({
    required String editionId,
    required int ordinal,
    required int chapter,
  }) =>
      this.editionId == editionId &&
      this.ordinal == ordinal &&
      this.chapter == chapter;
}

final pendingVerseHighlightProvider =
    NotifierProvider<PendingVerseHighlightNotifier, PendingVerseHighlight?>(
  PendingVerseHighlightNotifier.new,
);

class PendingVerseHighlightNotifier extends Notifier<PendingVerseHighlight?> {
  @override
  PendingVerseHighlight? build() => null;

  void request(PendingVerseHighlight value) => state = value;

  /// Reads the pending highlight if it matches the given chapter, and clears
  /// it in the same call so the next render won't re-trigger it.
  PendingVerseHighlight? takeFor({
    required String editionId,
    required int ordinal,
    required int chapter,
  }) {
    final value = state;
    if (value == null) return null;
    if (!value.matches(
      editionId: editionId,
      ordinal: ordinal,
      chapter: chapter,
    )) {
      return null;
    }
    state = null;
    return value;
  }

  void clear() => state = null;
}
