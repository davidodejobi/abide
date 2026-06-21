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

/// A continuous range of verses inside a single book, used by tablet links
/// that quote sermon-length passages like `JHN.3.16-18` or `JHN.3.16-4.5`.
class VerseRange {
  const VerseRange(this.start, this.end);

  final VerseRef start;
  final VerseRef end;

  /// Single-verse range (start == end).
  VerseRange.single(VerseRef ref)
      : start = ref,
        end = ref;

  /// True if the range spans more than one verse.
  bool get isRange => start != end;

  /// Parses any of:
  ///   `JHN.3.16`              single verse
  ///   `JHN.3.16-18`           range within a chapter
  ///   `JHN.3.16-4.5`          cross-chapter range, same book
  ///
  /// Returns null on malformed input, unknown book code, or a range whose
  /// end falls before its start.
  static VerseRange? tryParse(String raw) {
    final input = raw.trim();
    final dash = input.indexOf('-');
    if (dash == -1) {
      final single = VerseRef.tryParse(input);
      return single == null ? null : VerseRange.single(single);
    }

    final left = VerseRef.tryParse(input.substring(0, dash));
    if (left == null) return null;
    final right = input.substring(dash + 1).trim();
    final rightParts = right.split('.');

    VerseRef? endRef;
    if (rightParts.length == 1) {
      // `JHN.3.16-18` -> end shares book + chapter with start.
      final verse = int.tryParse(rightParts[0]);
      if (verse == null || verse < 1) return null;
      endRef = VerseRef(left.book, left.chapter, verse);
    } else if (rightParts.length == 2) {
      // `JHN.3.16-4.5` -> end is in the same book, different chapter+verse.
      final chapter = int.tryParse(rightParts[0]);
      final verse = int.tryParse(rightParts[1]);
      if (chapter == null || verse == null || chapter < 1 || verse < 1) {
        return null;
      }
      endRef = VerseRef(left.book, chapter, verse);
    } else if (rightParts.length == 3) {
      // `JHN.3.16-JHN.4.5` -> tolerate the redundant book; reject mismatches.
      final fullEnd = VerseRef.tryParse(right);
      if (fullEnd == null || fullEnd.book != left.book) return null;
      endRef = fullEnd;
    } else {
      return null;
    }

    if (_orderKey(endRef) < _orderKey(left)) return null;
    return VerseRange(left, endRef);
  }

  static int _orderKey(VerseRef r) => r.chapter * 1000 + r.verse;

  @override
  String toString() {
    if (!isRange) return start.toString();
    if (start.chapter == end.chapter) {
      return '${start.book}.${start.chapter}.${start.verse}-${end.verse}';
    }
    return '${start.book}.${start.chapter}.${start.verse}-${end.chapter}.${end.verse}';
  }

  @override
  bool operator ==(Object other) =>
      other is VerseRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}
