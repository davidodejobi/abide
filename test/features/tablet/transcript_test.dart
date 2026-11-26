import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/providers/service_providers.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/core/utils/services/file_storage_service.dart';
import 'package:openbaptisthymnal/features/tablet/data/transcribe_engine.dart';
import 'package:openbaptisthymnal/features/tablet/domain/note_media.dart';
import 'package:openbaptisthymnal/features/tablet/domain/recording_note.dart';
import 'package:openbaptisthymnal/features/tablet/providers/transcript_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    final back = Transcript.fromJson(
        jsonDecode(jsonEncode(t.toJson())) as Map<String, dynamic>);
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
    expect(
        pieces.where((p) => p.targetKey != null).single.targetKey, 'JHN.15.5');
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

  test('copy to note: t: link on each group head, then the scriptures list',
      () {
    const more = [
      ...segs,
      TranscriptSegment(66000, 69000, 'Second line of the same minute.'),
    ];
    final nodes = transcriptNodes(more, manifest);
    // heading, 3 paragraphs, heading, one bullet
    expect(nodes.map((n) => n.type).toList(), [
      'heading',
      'paragraph',
      'paragraph',
      'paragraph',
      'heading',
      'bulleted_list'
    ]);
    expect(
        nodes[1].delta!.toPlainText(), '00:00 Now Jesus says, remain in me.');
    final head = nodes[2].delta!.toList().first.toJson();
    expect(head['insert'], '01:05');
    expect((head['attributes'] as Map)['href'], 't:65');
    // Not a group head: plain text, no link.
    expect(nodes[3].delta!.toPlainText(), 'Second line of the same minute.');
    expect(nodes[3].delta!.toList().first.toJson()['attributes'], isNull);
    expect(nodes[4].delta!.toPlainText(), 'Scriptures mentioned');
    expect(nodes[5].delta!.toPlainText(), '[[bible:JHN.15.5]]');
  });

  test('copied transcript lines are not ticks on the pinned scrubber', () {
    final audio =
        audioMediaNode(url: 'a.m4a', name: 'A', durationMs: 90000, peaks: '');
    final doc = Document(
        root: pageNode(children: [
      audio,
      markerParagraph(const RecordingMarker(5000)),
      ...transcriptNodes(segs, manifest),
    ]));
    expect(timeLinkSecondsIn(doc), [5]);
  });

  test('a saved part sits beside the audio and never replaces the transcript',
      () {
    expect(transcriptPartPathFor('note_audio/abc.m4a'),
        'note_audio/abc.transcript.part.json');
    expect(transcriptPartPathFor('note_audio/abc.m4a'),
        isNot(transcriptPathFor('note_audio/abc.m4a')));
    final t = Transcript.fromJson({
      'language': 'en',
      'cancelled': true,
      'durationMs': 90000,
      'doneMs': 60000,
      'segments': <Object>[],
    });
    expect(t.cancelled, isTrue);
    expect(t.durationMs, 90000);
  });

  group('hymn titles', () {
    final matcher = HymnTitleMatcher(const [
      HymnTitle('hymn_0001', 'Holy, Holy, Holy', 'en'),
      HymnTitle('hymn_0010', 'Abide With Me', 'en'),
      HymnTitle('hymn_0020', 'Amen', 'en'),
      HymnTitle('hymn_0030', 'Rock of Ages', 'en'),
    ]);

    test('exact titles of three words or more link, any case', () {
      final pieces = splitTranscriptText(
          'We sang abide with me, then holy holy holy.', manifest, matcher);
      expect(pieces.where((p) => p.hymn != null).map((p) => p.hymn!.id),
          ['hymn_0010', 'hymn_0001']);
      expect(pieces.map((p) => p.text).join(),
          'We sang abide with me, then holy holy holy.');
    });

    test('short titles and partial phrases stay plain', () {
      final pieces = splitTranscriptText(
          'Amen. Abide with you. Rock of Agesx. The rock of ages',
          manifest,
          matcher);
      expect(pieces.where((p) => p.hymn != null).map((p) => p.hymn!.id),
          ['hymn_0030']); // only the whole-phrase "rock of ages"
    });
  });

  group('transcript notifier', () {
    const audio = 'note_audio/a.m4a';
    const key = (path: audio, durationMs: 150000);
    final finalPath = transcriptPathFor(audio);
    final partPath = transcriptPartPathFor(audio);

    late SharedPreferences prefs;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    ProviderContainer make(Map<String, String> files, List<List<int>> calls,
        {bool fail = false}) {
      return ProviderContainer(overrides: [
        fileStorageServiceProvider.overrideWithValue(_MemFiles(files)),
        sharedPreferencesProvider.overrideWithValue(prefs),
        durationProbeProvider.overrideWithValue((_) async => 150000),
        chunkTranscriberProvider
            .overrideWithValue((path, start, end, lang) async {
          calls.add([start, end]);
          if (fail) throw const TranscribeException(TranscribeFailure.failed);
          return [TranscriptSegment(start, end, 'chunk $start')];
        }),
      ]);
    }

    Future<void> settle(ProviderContainer c) async {
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }

    test('a saved part resumes where it stopped and the finished file swaps in',
        () async {
      final files = {
        partPath: jsonEncode(const Transcript(
            language: 'en',
            doneMs: 60000,
            durationMs: 150000,
            segments: [TranscriptSegment(0, 60000, 'chunk 0')]).toJson()),
      };
      final calls = <List<int>>[];
      final c = make(files, calls);
      c.read(transcriptProvider(key));
      await settle(c);
      expect(calls, [
        [60000, 120000],
        [120000, 150000]
      ]);
      final done = Transcript.fromJson(
          jsonDecode(files[finalPath]!) as Map<String, dynamic>);
      expect(done.complete, isTrue);
      expect(done.segments.length, 3);
      expect(files.containsKey(partPath), isFalse);
    });

    test('a stopped part does not auto-resume', () async {
      final files = {
        partPath: jsonEncode(const Transcript(
                language: 'en',
                doneMs: 60000,
                cancelled: true,
                durationMs: 150000)
            .toJson()),
      };
      final calls = <List<int>>[];
      final c = make(files, calls);
      c.read(transcriptProvider(key));
      await settle(c);
      expect(calls, isEmpty);
    });

    test(
        'a finished transcript is only replaced on request, and a failed '
        'replacement leaves it untouched', () async {
      final original = jsonEncode(const Transcript(
          language: 'en',
          doneMs: 150000,
          complete: true,
          durationMs: 150000,
          segments: [TranscriptSegment(0, 1000, 'kept')]).toJson());
      final files = {finalPath: original};
      final calls = <List<int>>[];
      final c = make(files, calls, fail: true);
      final n = c.read(transcriptProvider(key).notifier);
      await settle(c);
      await n.start('en'); // no replace: nothing runs
      expect(calls, isEmpty);
      await n.start('en', replace: true);
      expect(calls, isNotEmpty);
      expect(files[finalPath], original);
      expect(c.read(transcriptProvider(key)).failure, TranscribeFailure.failed);
      expect(c.read(transcriptProvider(key)).transcript!.complete, isTrue);
    });
  });

  test('runs are serialised: the second waits for the first', () async {
    final order = <String>[];
    final gate = Completer<void>();
    final a = runSerially(() async {
      order.add('a start');
      await gate.future;
      order.add('a end');
    });
    final b = runSerially(() async => order.add('b'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(order, ['a start']);
    gate.complete();
    await Future.wait([a, b]);
    expect(order, ['a start', 'a end', 'b']);
  });
}

class _MemFiles extends FileStorageService {
  _MemFiles(this.files);
  final Map<String, String> files;
  @override
  Future<void> writeText(String path, String text) async => files[path] = text;
  @override
  Future<String?> readText(String path) async => files[path];
  @override
  Future<void> deleteFile(String path) async => files.remove(path);
}
