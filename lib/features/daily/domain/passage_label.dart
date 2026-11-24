import 'package:openbaptisthymnal/features/bible/domain/verse_ref.dart';

/// Renders a plan day's passages as a reader would say them: "Genesis 1-4",
/// "Psalm 119", "Malachi 4, Matthew 1".
///
/// Chapters only. Plan days are always whole chapters (see `plan_generator`), so
/// printing "Genesis 1:1-4:26" would be technically true and needlessly loud --
/// nobody says it that way, and the verse numbers are an artifact of how the
/// range is stored rather than anything the reader has to act on.
///
/// [bookNames] maps a USFM code to the display name in the edition the reader
/// is actually using, so a Yoruba reader sees Yoruba book names. Falls back to
/// the raw code rather than dropping the passage: a card reading "GEN 1-4" is
/// ugly, but a card that silently omits today's reading is broken.
String formatPassages(
  List<VerseRange> passages,
  Map<String, String> bookNames, {
  String separator = ', ',
}) {
  return passages.map((p) => _one(p, bookNames)).join(separator);
}

String _one(VerseRange passage, Map<String, String> bookNames) {
  final name = bookNames[passage.start.book] ?? passage.start.book;
  final from = passage.start.chapter;
  final to = passage.end.chapter;

  // En dash, matching formatVerseRange in the Bible feature.
  return from == to ? '$name $from' : '$name $from–$to';
}
