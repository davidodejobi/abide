import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';
import 'package:openbaptisthymnal/features/tablet/domain/recording_note.dart';
import 'package:openbaptisthymnal/features/tablet/domain/scripture_reference.dart';
import 'package:path/path.dart' as p;

/// Audio is transcribed this much at a time and saved after every chunk, so a
/// kill (iOS ends background work in seconds) resumes at the last chunk.
const transcriptChunkMs = 60000;

/// Languages offered by the picker, in order. Only [freeTranscriptLanguages]
/// can be transcribed for now.
const transcriptLanguages = {
  'en': 'English',
  'yo': 'Yorùbá',
  'ha': 'Hausa',
  'ig': 'Igbo',
};
const freeTranscriptLanguages = {'en'};

bool transcriptLanguageSupported(String code) =>
    freeTranscriptLanguages.contains(code);

class TranscriptSegment {
  const TranscriptSegment(this.startMs, this.endMs, this.text);

  final int startMs;
  final int endMs;
  final String text;

  Map<String, Object> toJson() =>
      {'startMs': startMs, 'endMs': endMs, 'text': text};

  factory TranscriptSegment.fromJson(Map<String, dynamic> j) =>
      TranscriptSegment(
          j['startMs'] as int, j['endMs'] as int, j['text'] as String);
}

/// What is stored in `<audio uuid>.transcript.json`: the segments so far and
/// how far into the audio they cover ([doneMs]), which is where a resume
/// starts.
class Transcript {
  const Transcript({
    required this.language,
    this.doneMs = 0,
    this.complete = false,
    this.segments = const [],
  });

  final String language;
  final int doneMs;
  final bool complete;
  final List<TranscriptSegment> segments;

  /// The saved transcript after the chunk ending at [endMs] finished.
  Transcript withChunk(int endMs, List<TranscriptSegment> chunk,
          {required int durationMs}) =>
      Transcript(
        language: language,
        doneMs: endMs,
        complete: endMs >= durationMs,
        segments: [...segments, ...chunk],
      );

  /// The next `(start, end)` to transcribe, or null when finished.
  (int, int)? nextChunk(int durationMs) {
    if (complete || doneMs >= durationMs) return null;
    final end = doneMs + transcriptChunkMs;
    return (doneMs, end > durationMs ? durationMs : end);
  }

  double progress(int durationMs) =>
      durationMs <= 0 ? 0 : (doneMs / durationMs).clamp(0.0, 1.0);

  Map<String, Object> toJson() => {
        'v': 1,
        'language': language,
        'doneMs': doneMs,
        'complete': complete,
        'segments': [for (final s in segments) s.toJson()],
      };

  factory Transcript.fromJson(Map<String, dynamic> j) => Transcript(
        language: j['language'] as String? ?? 'en',
        doneMs: j['doneMs'] as int? ?? 0,
        complete: j['complete'] as bool? ?? false,
        segments: [
          for (final s in (j['segments'] as List? ?? const []))
            TranscriptSegment.fromJson(s as Map<String, dynamic>),
        ],
      );
}

/// `note_audio/<uuid>.m4a` -> `note_audio/<uuid>.transcript.json`.
String transcriptPathFor(String audioPath) =>
    '${p.withoutExtension(audioPath)}.transcript.json';

/// Index of the segment playing at [positionMs] (the last one that started),
/// or -1 before the first. [segments] must be in time order.
int activeSegmentIndex(List<TranscriptSegment> segments, int positionMs) {
  var lo = 0, hi = segments.length - 1, best = -1;
  while (lo <= hi) {
    final mid = (lo + hi) >> 1;
    if (segments[mid].startMs <= positionMs) {
      best = mid;
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  return best;
}

/// Segment indexes grouped under one timestamp pill: a new group starts once
/// a segment begins [transcriptChunkMs] after the group's first.
List<List<int>> groupSegments(List<TranscriptSegment> segments) {
  final out = <List<int>>[];
  for (var i = 0; i < segments.length; i++) {
    if (out.isEmpty ||
        segments[i].startMs - segments[out.last.first].startMs >=
            transcriptChunkMs) {
      out.add([]);
    }
    out.last.add(i);
  }
  return out;
}

/// A run of transcript text: plain, or a Bible reference ([targetKey] set).
class TranscriptPiece {
  const TranscriptPiece(this.text, [this.targetKey]);
  final String text;
  final String? targetKey;
}

/// Splits [text] around the Bible references in it. The words stay as spoken.
List<TranscriptPiece> splitTranscriptText(
    String text, BibleManifest? manifest) {
  if (manifest == null) return [TranscriptPiece(text)];
  final out = <TranscriptPiece>[];
  var cursor = 0;
  for (final r in findScriptureReferences(text, manifest)) {
    if (r.start < cursor) continue;
    if (r.start > cursor) {
      out.add(TranscriptPiece(text.substring(cursor, r.start)));
    }
    out.add(TranscriptPiece(text.substring(r.start, r.end), r.targetKey));
    cursor = r.end;
  }
  if (cursor < text.length) out.add(TranscriptPiece(text.substring(cursor)));
  return out;
}

/// "Copy to note": one paragraph per segment, each opening with a
/// `[mm:ss](t:sec)` link.
List<Node> transcriptNodes(List<TranscriptSegment> segments) => [
      for (final s in segments)
        paragraphNode(
          delta: Delta()
            ..insert(formatClock(s.startMs ~/ 1000 * 1000), attributes: {
              AppFlowyRichTextKeys.href: '$timeLinkScheme${s.startMs ~/ 1000}',
            })
            ..insert(' ${s.text}'),
        ),
    ];
