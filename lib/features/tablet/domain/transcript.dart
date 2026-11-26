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
    this.cancelled = false,
    this.durationMs = 0,
    this.segments = const [],
  });

  final String language;
  final int doneMs;
  final bool complete;

  /// The user stopped this run: opening the note does not resume it.
  final bool cancelled;

  /// Length of the audio when the run started, for "31:20 of 1:02:14".
  final int durationMs;
  final List<TranscriptSegment> segments;

  Transcript copyWith({bool? cancelled}) => Transcript(
        language: language,
        doneMs: doneMs,
        complete: complete,
        cancelled: cancelled ?? this.cancelled,
        durationMs: durationMs,
        segments: segments,
      );

  /// The saved transcript after the chunk ending at [endMs] finished.
  Transcript withChunk(int endMs, List<TranscriptSegment> chunk,
          {required int durationMs}) =>
      Transcript(
        language: language,
        doneMs: endMs,
        complete: endMs >= durationMs,
        durationMs: durationMs,
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
        'cancelled': cancelled,
        'durationMs': durationMs,
        'segments': [for (final s in segments) s.toJson()],
      };

  factory Transcript.fromJson(Map<String, dynamic> j) => Transcript(
        language: j['language'] as String? ?? 'en',
        doneMs: j['doneMs'] as int? ?? 0,
        complete: j['complete'] as bool? ?? false,
        cancelled: j['cancelled'] as bool? ?? false,
        durationMs: j['durationMs'] as int? ?? 0,
        segments: [
          for (final s in (j['segments'] as List? ?? const []))
            TranscriptSegment.fromJson(s as Map<String, dynamic>),
        ],
      );
}

/// `note_audio/<uuid>.m4a` -> `note_audio/<uuid>.transcript.json`.
String transcriptPathFor(String audioPath) =>
    '${p.withoutExtension(audioPath)}.transcript.json';

/// Where a run in progress is saved. Only a finished transcript is ever
/// written to [transcriptPathFor], so a half-done replacement never overwrites
/// a complete one.
String transcriptPartPathFor(String audioPath) =>
    '${p.withoutExtension(audioPath)}.transcript.part.json';

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

/// A hymn the transcript text names by its exact title.
class HymnTitle {
  const HymnTitle(this.id, this.title, this.pack);
  final String id;
  final String title;
  final String pack;
}

/// Finds hymn titles in text: case-insensitive, whole phrase, punctuation
/// between words ignored, and only titles of 3 words or more (shorter ones
/// are too common in speech). Longest titles win.
class HymnTitleMatcher {
  HymnTitleMatcher(Iterable<HymnTitle> titles)
      : _entries = [
          for (final t in titles)
            if (_words(t.title).length >= 3)
              (
                t,
                RegExp(
                  '(?<![\\p{L}\\p{N}\'])'
                  '${_words(t.title).map(RegExp.escape).join(r"[^\p{L}\p{N}']+")}'
                  '(?![\\p{L}\\p{N}\'])',
                  caseSensitive: false,
                  unicode: true,
                ),
              ),
        ]..sort((a, b) => b.$1.title.length.compareTo(a.$1.title.length));

  final List<(HymnTitle, RegExp)> _entries;

  static List<String> _words(String s) => [
        for (final m in RegExp(r"[\p{L}\p{N}']+", unicode: true).allMatches(s))
          m[0]!,
      ];

  /// Non-overlapping matches as (start, end, title), in text order.
  List<(int, int, HymnTitle)> find(String text) {
    final hits = <(int, int, HymnTitle)>[];
    for (final (title, re) in _entries) {
      for (final m in re.allMatches(text)) {
        if (hits.any((h) => m.start < h.$2 && m.end > h.$1)) continue;
        hits.add((m.start, m.end, title));
      }
    }
    return hits..sort((a, b) => a.$1.compareTo(b.$1));
  }
}

/// A run of transcript text: plain, a Bible reference ([targetKey] set), or a
/// hymn ([hymn] set).
class TranscriptPiece {
  const TranscriptPiece(this.text, [this.targetKey, this.hymn]);
  final String text;
  final String? targetKey;
  final HymnTitle? hymn;
}

/// Splits [text] around the Bible references (spoken forms included) and hymn
/// titles in it. The words stay as spoken.
List<TranscriptPiece> splitTranscriptText(
  String text,
  BibleManifest? manifest, [
  HymnTitleMatcher? hymns,
]) {
  final spans = <(int, int, String?, HymnTitle?)>[
    if (manifest != null)
      for (final r in findSpokenScriptureReferences(text, manifest))
        (r.start, r.end, r.targetKey, null),
  ];
  for (final h in hymns?.find(text) ?? const <(int, int, HymnTitle)>[]) {
    if (spans.any((s) => h.$1 < s.$2 && h.$2 > s.$1)) continue;
    spans.add((h.$1, h.$2, null, h.$3));
  }
  spans.sort((a, b) => a.$1.compareTo(b.$1));
  final out = <TranscriptPiece>[];
  var cursor = 0;
  for (final s in spans) {
    if (s.$1 < cursor) continue;
    if (s.$1 > cursor) {
      out.add(TranscriptPiece(text.substring(cursor, s.$1)));
    }
    out.add(TranscriptPiece(text.substring(s.$1, s.$2), s.$3, s.$4));
    cursor = s.$2;
  }
  if (cursor < text.length) out.add(TranscriptPiece(text.substring(cursor)));
  return out;
}

/// "Copy to note": a Transcript heading, one paragraph per segment with a
/// `[mm:ss](t:sec)` link at the head of each timestamp group, then a
/// `## Scriptures mentioned` list of the unique references as `[[bible:...]]`.
/// The heading keeps these paragraphs from reading as recording markers.
List<Node> transcriptNodes(
    List<TranscriptSegment> segments, BibleManifest? manifest) {
  final heads = {for (final g in groupSegments(segments)) g.first};
  final refs = <String>{
    if (manifest != null)
      for (final s in segments)
        for (final r in findSpokenScriptureReferences(s.text, manifest))
          r.targetKey,
  };
  return [
    headingNode(level: 2, text: 'Transcript'),
    for (var i = 0; i < segments.length; i++)
      paragraphNode(
        delta: heads.contains(i)
            ? (Delta()
              ..insert(formatClock(segments[i].startMs ~/ 1000 * 1000),
                  attributes: {
                    AppFlowyRichTextKeys.href:
                        '$timeLinkScheme${segments[i].startMs ~/ 1000}',
                  })
              ..insert(' ${segments[i].text}'))
            : (Delta()..insert(segments[i].text)),
      ),
    if (refs.isNotEmpty) ...[
      headingNode(level: 2, text: 'Scriptures mentioned'),
      for (final k in refs) bulletedListNode(text: '[[bible:$k]]'),
    ],
  ];
}
