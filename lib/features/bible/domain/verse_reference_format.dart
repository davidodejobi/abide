/// Formats a set of selected verse numbers into a human-readable citation
/// tail like `3:16` or `3:16–18` or `3:16–17, 19`. Consecutive runs collapse
/// into en-dash ranges; gaps split into comma-separated groups. Combine with a
/// book name (`'${book.name} ${formatVerseRange(...)}'`) for a full reference.
String formatVerseRange(int chapter, Iterable<int> verses) {
  final sorted = verses.toSet().toList()..sort();
  if (sorted.isEmpty) return '$chapter';

  final groups = <String>[];
  var runStart = sorted.first;
  var runEnd = sorted.first;

  void flush() {
    groups.add(runStart == runEnd ? '$runStart' : '$runStart–$runEnd');
  }

  for (final n in sorted.skip(1)) {
    if (n == runEnd + 1) {
      runEnd = n;
    } else {
      flush();
      runStart = n;
      runEnd = n;
    }
  }
  flush();

  return '$chapter:${groups.join(', ')}';
}
