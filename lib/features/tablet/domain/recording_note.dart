import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:openbaptisthymnal/features/tablet/domain/note_media.dart';

/// A bookmark dropped while recording: [ms] into the take plus an optional
/// short label.
class RecordingMarker {
  const RecordingMarker(this.ms, [this.label = '']);
  final int ms;
  final String label;

  RecordingMarker withLabel(String l) => RecordingMarker(ms, l.trim());
}

/// `14:02`, or `1:02:03` from one hour up.
String formatClock(int ms) {
  final s = (ms < 0 ? 0 : ms) ~/ 1000;
  final h = s ~/ 3600;
  final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
  final sec = (s % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$sec' : '$m:$sec';
}

const timeLinkScheme = 't:';

/// Seconds in a `t:842` link target, or null when [href] is not one.
int? timeLinkSeconds(String? href) {
  if (href == null || !href.startsWith(timeLinkScheme)) return null;
  return int.tryParse(href.substring(timeLinkScheme.length));
}

/// One marker as a note paragraph: `[14:02](t:842) label` (label optional).
Node markerParagraph(RecordingMarker m) {
  final seconds = m.ms ~/ 1000;
  final delta = Delta()
    ..insert(formatClock(seconds * 1000),
        attributes: {AppFlowyRichTextKeys.href: '$timeLinkScheme$seconds'});
  if (m.label.isNotEmpty) delta.insert(' ${m.label}');
  return paragraphNode(delta: delta);
}

/// The audio block followed by one paragraph per marker, in time order.
List<Node> recordingNodes({
  required String url,
  required String name,
  required int durationMs,
  required String peaks,
  List<RecordingMarker> markers = const [],
}) =>
    [
      audioMediaNode(
          url: url, name: name, durationMs: durationMs, peaks: peaks),
      for (final m in [...markers]..sort((a, b) => a.ms.compareTo(b.ms)))
        markerParagraph(m),
    ];

/// Every `t:` link in [document], as seconds (for the player's marker ticks).
List<int> timeLinkSecondsIn(Document document) {
  final out = <int>[];
  void walk(Node n) {
    for (final op in n.delta ?? const <TextOperation>[]) {
      if (op is TextInsert) {
        final s = timeLinkSeconds(
            op.attributes?[AppFlowyRichTextKeys.href] as String?);
        if (s != null) out.add(s);
      }
    }
    n.children.forEach(walk);
  }

  walk(document.root);
  return out;
}

/// The note's first audio block, which the pinned player and `t:` links drive.
Node? firstAudioNode(Document document) {
  Node? find(Node n) {
    if (n.type == audioNodeType) return n;
    for (final c in n.children) {
      final f = find(c);
      if (f != null) return f;
    }
    return null;
  }

  return find(document.root);
}

/// Every top-level audio block, in document order.
List<Node> audioNodes(Document document) =>
    [for (final n in document.root.children) if (n.type == audioNodeType) n];

/// The audio block a `t:` link at [linkPath] refers to: the nearest one above
/// it, else the first in the note.
Node? audioNodeAbove(Document document, List<int> linkPath) {
  final audios = audioNodes(document);
  if (audios.isEmpty) return null;
  Node? best;
  for (final a in audios) {
    if (a.path.first < linkPath.first) best = a;
  }
  return best ?? audios.first;
}

bool _isMarkerParagraph(Node n) {
  final ops = n.delta?.toList();
  if (n.type != ParagraphBlockKeys.type || ops == null || ops.isEmpty) {
    return false;
  }
  final first = ops.first;
  return first is TextInsert &&
      timeLinkSeconds(first.attributes?[AppFlowyRichTextKeys.href] as String?) !=
          null;
}

/// Where a new take goes: the top of a note with no recording, else right
/// after the last recording and its marker paragraphs.
int recordingInsertIndex(Document document) {
  final kids = document.root.children.toList();
  final last = kids.lastIndexWhere((n) => n.type == audioNodeType);
  if (last < 0) return 0;
  var i = last + 1;
  while (i < kids.length && _isMarkerParagraph(kids[i])) {
    i++;
  }
  return i;
}
