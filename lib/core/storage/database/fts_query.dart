/// Turns raw search-box text into a safe FTS5 `MATCH` expression.
///
/// Each whitespace-separated token is wrapped in double quotes (so user
/// punctuation can't be parsed as an FTS operator) with embedded quotes doubled
/// per the FTS5 string-literal rules, then given a trailing `*` for prefix
/// matching. Tokens are space-joined, which FTS5 treats as implicit AND.
/// Returns an empty string for blank input so callers can skip the query.
String buildFtsMatchQuery(String raw) {
  final tokens = raw.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
  return tokens.map((t) => '"${t.replaceAll('"', '""')}"*').join(' ');
}
