import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';
import 'package:openbaptisthymnal/features/tablet/domain/transcript.dart';

final manifest = BibleManifest.fromJson(
    jsonDecode(File('assets/bible/en-kjv/manifest.json').readAsStringSync())
        as Map<String, dynamic>);

void main() {
  const segs = [
    TranscriptSegment(0, 4000, 'Now Jesus says, remain in me.'),
    TranscriptSegment(65000, 70000, 'It is by grace (John 15:5).'),
  ];

  test('segments round-trip through JSON', () {
    const t = Transcript(language: 'en', doneMs: 70000, segments: segs);
    final back =
        Transcript.fromJson(jsonDecode(jsonEncode(t.toJson())) as Map<String, dynamic>);
    expect(back.language, 'en');
    expect(back.doneMs, 70000);
    expect(back.complete, isFalse);
    expect(back.segments.map((s) => (s.startMs, s.endMs, s.text)),
        segs.map((s) => (s.startMs, s.endMs, s.text)));
  });

  test('transcript sits next to its audio with the same uuid', () {
    expect(transcriptPathFor('note_audio/abc-123.m4a'),
        'note_audio/abc-123.transcript.json');
  });

  test('chunks resume where the saved part stopped', () {
    const duration = 150000; // 2:30
    var t = const Transcript(language: 'en');
    expect(t.nextChunk(duration), (0, 60000));
    t = t.withChunk(60000, [segs[0]], durationMs: duration);
    // A kill here: the file holds doneMs 60000, reopening starts there.
    final reopened = Transcript.fromJson(t.toJson());
    expect(reopened.nextChunk(duration), (60000, 120000));
    expect(reopened.progress(duration), closeTo(0.4, 1e-9));
    t = reopened.withChunk(120000, [segs[1]], durationMs: duration);
    expect(t.nextChunk(duration), (120000, 150000));
    t = t.withChunk(150000, const [], durationMs: duration);
    expect(t.complete, isTrue);
    expect(t.nextChunk(duration), isNull);
    expect(t.segments.length, 2);
  });

  test('only English is free for now', () {
    expect(transcriptLanguages.keys, ['en', 'yo', 'ha', 'ig']);
    expect(transcriptLanguageSupported('en'), isTrue);
    for (final c in ['yo', 'ha', 'ig']) {
      expect(transcriptLanguageSupported(c), isFalse);
    }
  });

  test('scripture references in a row become tappable pieces', () {
    final pieces = splitTranscriptText(segs[1].text, manifest);
    expect(pieces.map((p) => p.text).join(), segs[1].text);
    expect(pieces.where((p) => p.targetKey != null).single.targetKey, 'JHN.15.5');
    expect(splitTranscriptText('Plain words only.', manifest).single.targetKey,
        isNull);
    expect(splitTranscriptText('John 3:16', null).single.targetKey, isNull);
  });

  test('active segment follows the playhead; rows group by minute', () {
    expect(activeSegmentIndex(segs, -1), -1);
    expect(activeSegmentIndex(segs, 1000), 0);
    expect(activeSegmentIndex(segs, 66000), 1);
    expect(groupSegments(segs), [
      [0],
      [1]
    ]);
  });

  test('copy to note: one paragraph per segment led by a t: link', () {
    final nodes = transcriptNodes(segs);
    expect(nodes.length, 2);
    final ops = nodes[1].delta!.toList();
    expect(ops.first.toJson()['insert'], '01:05');
    expect((ops.first.toJson()['attributes'] as Map)['href'], 't:65');
    expect(nodes[1].delta!.toPlainText(), '01:05 It is by grace (John 15:5).');
  });
}
