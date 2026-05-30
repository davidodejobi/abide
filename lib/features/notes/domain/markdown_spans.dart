/// Inline style applied to a slice of note markdown for live rendering in the
/// editor. Markers (`**`, `*`, `[[`, `# `) stay in the text — markdown is the
/// source of truth — they are just styled rather than hidden.
enum MarkdownRunType { plain, bold, italic, link, heading }

/// A contiguous slice of text [start, end) that should be drawn with [type].
/// For [MarkdownRunType.link], [linkInner] holds the token's inner contents
/// (e.g. `hymn:hymn_0001`).
class MarkdownRun {
  const MarkdownRun({
    required this.start,
    required this.end,
    required this.type,
    this.linkInner,
  });

  final int start;
  final int end;
  final MarkdownRunType type;
  final String? linkInner;

  @override
  bool operator ==(Object other) =>
      other is MarkdownRun &&
      other.start == start &&
      other.end == end &&
      other.type == type &&
      other.linkInner == linkInner;

  @override
  int get hashCode => Object.hash(start, end, type, linkInner);

  @override
  String toString() => 'MarkdownRun($start-$end, $type, $linkInner)';
}

final _link = RegExp(r'\[\[[^\[\]]*\]\]');
final _bold = RegExp(r'\*\*[^\n]+?\*\*');
final _italic = RegExp(r'(?<!\*)\*(?!\*)[^\n*]+?\*(?!\*)');
final _heading = RegExp(r'^#{1,3} .*$', multiLine: true);

/// Tokenizes [text] into ordered, non-overlapping styled runs covering the
/// whole string. Higher-priority patterns (links, then bold, italic, heading)
/// claim their span first; remaining gaps become [MarkdownRunType.plain].
List<MarkdownRun> computeMarkdownRuns(String text) {
  if (text.isEmpty) return const [];

  final claimed = List<bool>.filled(text.length, false);
  final styled = <MarkdownRun>[];

  bool free(int start, int end) {
    for (var i = start; i < end; i++) {
      if (claimed[i]) return false;
    }
    return true;
  }

  void claim(int start, int end) {
    for (var i = start; i < end; i++) {
      claimed[i] = true;
    }
  }

  void collect(RegExp pattern, MarkdownRunType type) {
    for (final m in pattern.allMatches(text)) {
      if (!free(m.start, m.end)) continue;
      claim(m.start, m.end);
      String? inner;
      if (type == MarkdownRunType.link) {
        inner = text.substring(m.start + 2, m.end - 2).trim();
      }
      styled.add(MarkdownRun(
        start: m.start,
        end: m.end,
        type: type,
        linkInner: inner,
      ));
    }
  }

  collect(_link, MarkdownRunType.link);
  collect(_bold, MarkdownRunType.bold);
  collect(_italic, MarkdownRunType.italic);
  collect(_heading, MarkdownRunType.heading);

  styled.sort((a, b) => a.start.compareTo(b.start));

  // Stitch styled runs together with plain runs filling the gaps.
  final result = <MarkdownRun>[];
  var cursor = 0;
  for (final run in styled) {
    if (run.start > cursor) {
      result.add(MarkdownRun(
        start: cursor,
        end: run.start,
        type: MarkdownRunType.plain,
      ));
    }
    result.add(run);
    cursor = run.end;
  }
  if (cursor < text.length) {
    result.add(MarkdownRun(
      start: cursor,
      end: text.length,
      type: MarkdownRunType.plain,
    ));
  }
  return result;
}
