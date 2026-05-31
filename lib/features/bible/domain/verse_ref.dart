import 'package:openbaptisthymnal/features/bible/domain/book_codes.dart';

/// A canonical, language-independent pointer to a single verse, formatted as
/// `<CODE>.<chapter>.<verse>` (e.g. `JHN.3.16`). This is the alignment key that
/// lets any two editions sit side by side and the join key for annotations and
/// `[[bible:...]]` links.
class VerseRef {
  const VerseRef(this.book, this.chapter, this.verse);

  /// Canonical USFM book code, e.g. `JHN`.
  final String book;
  final int chapter;
  final int verse;

  /// 1-based canonical ordinal of [book], or null if the code is unknown.
  int? get ordinal => ordinalForBookCode(book);

  /// Parses `JHN.3.16`. Returns null if malformed or the book code is unknown.
  static VerseRef? tryParse(String raw) {
    final parts = raw.trim().split('.');
    if (parts.length != 3) return null;
    final code = parts[0].toUpperCase();
    if (ordinalForBookCode(code) == null) return null;
    final chapter = int.tryParse(parts[1]);
    final verse = int.tryParse(parts[2]);
    if (chapter == null || verse == null || chapter < 1 || verse < 1) {
      return null;
    }
    return VerseRef(code, chapter, verse);
  }

  @override
  String toString() => '$book.$chapter.$verse';

  @override
  bool operator ==(Object other) =>
      other is VerseRef &&
      other.book == book &&
      other.chapter == chapter &&
      other.verse == verse;

  @override
  int get hashCode => Object.hash(book, chapter, verse);
}
