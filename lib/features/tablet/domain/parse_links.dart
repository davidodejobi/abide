/// The kind of thing a `[[wikilink]]` points at.
enum NoteLinkType { note, hymn, bible }

/// A single `[[...]]` token parsed out of a note's markdown.
///
/// [targetKey] is the stable lookup value: a hymn id (`hymn_0001`), an OSIS
/// verse ref (`JHN.3.16`), or — for note links — the referenced title.
/// [display] is what should be shown inline (title for notes, the key for the
/// typed forms until resolved against real data).
class ParsedLink {
  const ParsedLink({
    required this.type,
    required this.targetKey,
    required this.rawToken,
    required this.display,
  });

  final NoteLinkType type;
  final String targetKey;
  final String rawToken;
  final String display;

  @override
  bool operator ==(Object other) =>
      other is ParsedLink &&
      other.type == type &&
      other.targetKey == targetKey &&
      other.rawToken == rawToken &&
      other.display == display;

  @override
  int get hashCode => Object.hash(type, targetKey, rawToken, display);

  @override
  String toString() =>
      'ParsedLink($type, key: $targetKey, raw: $rawToken, display: $display)';
}

final _linkPattern = RegExp(r'\[\[([^\[\]]*)\]\]');

/// Scans [markdown] for `[[...]]` tokens and returns the typed links in order
/// of appearance. Duplicates are removed (first occurrence wins). Tokens:
///
/// * `[[hymn:hymn_0001]]` → a hymn link
/// * `[[bible:JHN.3.16]]` → a scripture link
/// * `[[Some Note Title]]` → a note link (resolved by title later)
///
/// Empty or whitespace-only tokens (`[[]]`, `[[hymn:]]`) are skipped.
List<ParsedLink> parseLinks(String markdown) {
  final seen = <String>{};
  final result = <ParsedLink>[];

  for (final match in _linkPattern.allMatches(markdown)) {
    final inner = match.group(1)!.trim();
    if (inner.isEmpty) continue;

    final rawToken = match.group(0)!;
    final colon = inner.indexOf(':');
    final prefix = colon == -1 ? '' : inner.substring(0, colon).toLowerCase();
    final rest = colon == -1 ? inner : inner.substring(colon + 1).trim();

    late final ParsedLink link;
    switch (prefix) {
      case 'hymn':
        if (rest.isEmpty) continue;
        link = ParsedLink(
          type: NoteLinkType.hymn,
          targetKey: rest,
          rawToken: rawToken,
          display: rest,
        );
      case 'bible':
        if (rest.isEmpty) continue;
        link = ParsedLink(
          type: NoteLinkType.bible,
          targetKey: rest,
          rawToken: rawToken,
          display: rest,
        );
      default:
        link = ParsedLink(
          type: NoteLinkType.note,
          targetKey: inner,
          rawToken: rawToken,
          display: inner,
        );
    }

    if (seen.add('${link.type}:${link.targetKey.toLowerCase()}')) {
      result.add(link);
    }
  }

  return result;
}
