/// Detects an in-progress `[[` link the user is typing.
///
/// Given the full [text] and the current [cursor] offset, returns the query
/// typed after the nearest unclosed `[[` (the text between `[[` and the
/// cursor), or `null` when the cursor is not inside an open link token.
///
/// A token is considered closed/aborted if a `]]`, newline, or another `[[`
/// appears between the opening `[[` and the cursor.
String? linkAutocompleteQuery(String text, int cursor) {
  if (cursor < 2 || cursor > text.length) return null;

  final before = text.substring(0, cursor);
  final open = before.lastIndexOf('[[');
  if (open == -1) return null;

  final between = before.substring(open + 2);
  if (between.contains(']]') ||
      between.contains('\n') ||
      between.contains('[[')) {
    return null;
  }
  return between;
}

/// Splices a completed token into [text], replacing the active `[[query`
/// fragment that ends at [cursor] with [token] plus a closing `]]`.
/// Returns the new text and the caret offset placed just after `]]`.
({String text, int cursor}) applyLinkCompletion(
  String text,
  int cursor,
  String token,
) {
  final before = text.substring(0, cursor);
  final open = before.lastIndexOf('[[');
  final prefix = text.substring(0, open);
  final suffix = text.substring(cursor);
  final inserted = '[[$token]]';
  return (text: '$prefix$inserted$suffix', cursor: prefix.length + inserted.length);
}
