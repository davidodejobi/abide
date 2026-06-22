import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';

/// A single autocomplete suggestion for a Bible reference being typed inside
/// a `[[bible:...]]` token.
class BibleSuggestion {
  const BibleSuggestion({
    required this.token,
    required this.label,
    this.isChapter = false,
    this.isVerse = false,
  });

  /// The value to insert into the token (e.g. `bible:JHN` or `bible:JHN.3`).
  final String token;

  /// Human-readable label (e.g. `John (JHN)` or `John 3`).
  final String label;

  /// True when this suggestion represents a full chapter reference.
  final bool isChapter;

  /// True when this suggestion represents a full verse reference.
  final bool isVerse;
}

/// Parses the user's in-progress `bible:` query against the manifest and
/// returns a list of suggestions at the appropriate granularity:
///
///  * **No text after `bible:`** — first 5 books.
///  * **Partial book** — books whose code or name starts with the typed text.
///  * **Exact book** — all chapters of that book.
///  * **Book + chapter** — the chapter itself as a single suggestion.
///  * **Book + chapter + verse** — the verse as a single suggestion.
///  * **Missing / invalid chapter or verse** — empty list.
List<BibleSuggestion> bibleAutocompleteSuggestions(
  BibleManifest manifest,
  String query,
) {
  final trimmed = query.trim();
  if (!trimmed.startsWith('bible:')) return [];

  final rest = trimmed.substring(6); // everything after 'bible:'
  final parts = rest.split('.');

  // -- Step 1: no text yet → show first books ---------------------------------
  if (rest.isEmpty) {
    return manifest.books
        .take(5)
        .map((b) => BibleSuggestion(
              token: 'bible:${b.code}',
              label: '${b.name} (${b.code})',
            ))
        .toList();
  }

  // -- Step 2: resolve the book code / name -----------------------------------
  final bookInput = parts[0].trim();
  final book = _exactBook(manifest, bookInput);

  // Still searching for a book → show partial matches.
  if (book == null) {
    return manifest.books
        .where((b) => _matchesBook(b, bookInput))
        .take(5)
        .map((b) => BibleSuggestion(
              token: 'bible:${b.code}',
              label: '${b.name} (${b.code})',
            ))
        .toList();
  }

  // -- Step 3: exact book → show chapters ------------------------------------
  if (parts.length == 1) {
    return List.generate(
      book.chapterCount,
      (i) {
        final ch = i + 1;
        return BibleSuggestion(
          token: 'bible:${book.code}.$ch',
          label: '${book.name} $ch',
          isChapter: true,
        );
      },
    );
  }

  // -- Step 4: resolve the chapter number ------------------------------------
  final chapterInput = parts[1].trim();
  final chapterNum = int.tryParse(chapterInput);

  // Partial chapter number → filter chapter list.
  if (chapterNum == null) {
    return List.generate(
      book.chapterCount,
      (i) {
        final ch = i + 1;
        return BibleSuggestion(
          token: 'bible:${book.code}.$ch',
          label: '${book.name} $ch',
          isChapter: true,
        );
      },
    ).where((s) => s.label.contains(chapterInput)).take(5).toList();
  }

  // Chapter out of range → nothing.
  if (chapterNum < 1 || chapterNum > book.chapterCount) {
    return [];
  }

  // -- Step 5: exact chapter (with or without verse) -------------------------
  if (parts.length == 2) {
    return [
      BibleSuggestion(
        token: 'bible:${book.code}.$chapterNum',
        label: '${book.name} $chapterNum',
        isChapter: true,
      ),
    ];
  }

  // -- Step 6: resolve the verse number --------------------------------------
  final verseInput = parts.sublist(2).join('.');
  final verseParts = verseInput.split('-');
  final verseNum = int.tryParse(verseParts[0].trim());

  if (verseNum == null) return [];

  final verseCount = book.chapterVerseCounts[chapterNum - 1];
  if (verseNum < 1 || verseNum > verseCount) return [];

  return [
    BibleSuggestion(
      token: 'bible:${book.code}.$chapterNum.$verseInput',
      label: '${book.name} $chapterNum:$verseInput',
      isVerse: true,
    ),
  ];
}

/// Returns the book when [input] matches its code or name exactly.
BibleBookInfo? _exactBook(BibleManifest manifest, String input) {
  final needle = input.toUpperCase();
  for (final b in manifest.books) {
    if (b.code.toUpperCase() == needle) return b;
    if (b.name.toUpperCase() == needle) return b;
  }
  return null;
}

/// True when [input] matches the start of [book]'s code or name.
bool _matchesBook(BibleBookInfo book, String input) {
  final needle = input.toLowerCase();
  final code = book.code.toLowerCase();
  final name = book.name.toLowerCase();
  if (code == needle) return true;
  if (name == needle) return true;
  if (code.startsWith(needle)) return true;
  if (name.startsWith(needle)) return true;
  if (name.contains(' $needle')) return true;
  return false;
}
