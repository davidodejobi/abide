/// Lightweight per-edition index, loaded once so the book and chapter pickers
/// can render without decoding any book text. Mirrors `manifest.json`.
class BibleManifest {
  const BibleManifest({
    required this.edition,
    required this.language,
    required this.name,
    required this.books,
  });

  final String edition;
  final String language;
  final String name;
  final List<BibleBookInfo> books;

  factory BibleManifest.fromJson(Map<String, dynamic> json) {
    return BibleManifest(
      edition: json['edition'] as String,
      language: json['language'] as String,
      name: json['name'] as String,
      books: (json['books'] as List)
          .map((b) => BibleBookInfo.fromJson(b as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

/// One book's index entry: its canonical code, localized display name, and the
/// verse count of each chapter (length == number of chapters).
class BibleBookInfo {
  const BibleBookInfo({
    required this.ordinal,
    required this.code,
    required this.name,
    required this.chapterVerseCounts,
  });

  /// 1-based canonical ordinal.
  final int ordinal;

  /// Canonical USFM code, e.g. `JHN`.
  final String code;

  /// Localized display name as it appears in this edition.
  final String name;

  /// Verse count per chapter, in chapter order.
  final List<int> chapterVerseCounts;

  int get chapterCount => chapterVerseCounts.length;

  factory BibleBookInfo.fromJson(Map<String, dynamic> json) {
    return BibleBookInfo(
      ordinal: json['ordinal'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      chapterVerseCounts:
          (json['chapters'] as List).map((c) => c as int).toList(growable: false),
    );
  }
}
