/// The kind of thing a `[[wikilink]]` points at.
enum NoteLinkType { note, hymn, bible }

/// A single `[[...]]` token parsed out of a tablet's markdown.
///
/// [targetKey] is the stable lookup value: a hymn id (`hymn_0001`), an OSIS
/// verse ref or range (`JHN.3.16`, `JHN.3.16-18`), or for tablet links the
/// referenced title.
/// [editionPin] is an optional explicit edition the author wants to open this
/// link in, written as `[[bible:JHN.3.16:en-niv]]` or `[[hymn:hymn_0001:yo]]`.
/// Most links leave it null and let the resolver pick at click time.
/// [display] is what should be shown inline.
class ParsedLink {
  const ParsedLink({
    required this.type,
    required this.targetKey,
    required this.rawToken,
    required this.display,
    this.editionPin,
  });

  final NoteLinkType type;
  final String targetKey;
  final String rawToken;
  final String display;
  final String? editionPin;

  @override
  bool operator ==(Object other) =>
      other is ParsedLink &&
      other.type == type &&
      other.targetKey == targetKey &&
      other.rawToken == rawToken &&
      other.display == display &&
      other.editionPin == editionPin;

  @override
  int get hashCode =>
      Object.hash(type, targetKey, rawToken, display, editionPin);

  @override
  String toString() => 'ParsedLink($type, key: $targetKey, '
      'pin: $editionPin, raw: $rawToken, display: $display)';
}

final _linkPattern = RegExp(r'\[\[([^\[\]]*)\]\]');

/// Splits the body of a typed link (after `hymn:` or `bible:`) into a
/// `(targetKey, editionPin)` pair. Treats the rightmost colon as the pin
/// separator only when the suffix looks like an edition id (letters, digits,
/// and dashes — not a chapter/verse number).
///
/// `JHN.3.16` -> ('JHN.3.16', null)
/// `JHN.3.16:en-niv` -> ('JHN.3.16', 'en-niv')
/// `hymn_0001:yo` -> ('hymn_0001', 'yo')
({String targetKey, String? editionPin}) _splitEditionPin(String body) {
  final colon = body.lastIndexOf(':');
  if (colon == -1) return (targetKey: body, editionPin: null);
  final suffix = body.substring(colon + 1).trim();
  if (!_looksLikeEditionId(suffix)) {
    return (targetKey: body, editionPin: null);
  }
  final key = body.substring(0, colon).trim();
  if (key.isEmpty) return (targetKey: body, editionPin: null);
  return (targetKey: key, editionPin: suffix.toLowerCase());
}

final _editionIdPattern = RegExp(r'^[a-z][a-z0-9-]*$', caseSensitive: false);

bool _looksLikeEditionId(String s) {
  if (s.isEmpty) return false;
  return _editionIdPattern.hasMatch(s);
}

/// Scans [markdown] for `[[...]]` tokens and returns the typed links in order
/// of appearance. Duplicates are removed (first occurrence wins). Tokens:
///
/// * `[[hymn:hymn_0001]]`              hymn link, resolves at click time
/// * `[[hymn:hymn_0001:yo]]`           hymn link pinned to a language pack
/// * `[[bible:JHN.3.16]]`              single verse
/// * `[[bible:JHN.3.16-18]]`           verse range
/// * `[[bible:JHN.3.16:en-niv]]`       verse pinned to an edition
/// * `[[Some Tablet Title]]`           tablet link (resolved by title later)
///
/// Empty or whitespace-only tokens are skipped.
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
        final split = _splitEditionPin(rest);
        link = ParsedLink(
          type: NoteLinkType.hymn,
          targetKey: split.targetKey,
          rawToken: rawToken,
          display: split.targetKey,
          editionPin: split.editionPin,
        );
      case 'bible':
        if (rest.isEmpty) continue;
        final split = _splitEditionPin(rest);
        link = ParsedLink(
          type: NoteLinkType.bible,
          targetKey: split.targetKey,
          rawToken: rawToken,
          display: split.targetKey,
          editionPin: split.editionPin,
        );
      default:
        link = ParsedLink(
          type: NoteLinkType.note,
          targetKey: inner,
          rawToken: rawToken,
          display: inner,
        );
    }

    final dedupeKey =
        '${link.type}:${link.targetKey.toLowerCase()}:${link.editionPin ?? ''}';
    if (seen.add(dedupeKey)) {
      result.add(link);
    }
  }

  return result;
}
