import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/tablet/domain/note_media.dart';
import 'package:openbaptisthymnal/features/tablet/domain/parse_links.dart';
import 'package:openbaptisthymnal/features/tablet/domain/recording_note.dart';
import 'package:openbaptisthymnal/features/tablet/domain/tablet_markdown_codec.dart';
import 'package:openbaptisthymnal/features/tablet/domain/tablet_preview.dart';

void main() {
  audioPlacementTests();
  test('default recording title', () {
    expect(defaultRecordingName(DateTime(2026, 11, 26, 9, 5)),
        'Recording, 26 Nov, 09:05');
  });

  test('clock format', () {
    expect(formatClock(842000), '14:02');
    expect(formatClock(3723000), '1:02:03');
  });

  test('time link target', () {
    expect(timeLinkSeconds('t:842'), 842);
    expect(timeLinkSeconds('https://x.y'), isNull);
    expect(timeLinkSeconds('t:abc'), isNull);
    expect(timeLinkSeconds(null), isNull);
  });

  String md(List<RecordingMarker> markers) => noteDocumentToMarkdown(
        Document(
          root: pageNode(
            children: recordingNodes(
              url: '/x/y.m4a',
              name: 'Rec',
              durationMs: 900000,
              peaks: '',
              markers: markers,
            ),
          ),
        ),
      );

  test('markers become paragraphs under the audio block, in time order', () {
    final out = md(const [
      RecordingMarker(842500, 'Ask about forgiveness'),
      RecordingMarker(5000),
    ]);
    final lines = out.split('\n').where((l) => l.isNotEmpty).toList();
    expect(lines[0], startsWith('![Rec]('));
    expect(lines[1], '[00:05](t:5)');
    expect(lines[2], '[14:02](t:842) Ask about forgiveness');
  });

  test('t: links round-trip and are not wiki or web links', () {
    final out = md(const [RecordingMarker(842000, 'Grace')]);
    final again = noteDocumentToMarkdown(noteMarkdownToDocument(out));
    expect(again, out);
    final doc = noteMarkdownToDocument(out);
    expect(timeLinkSecondsIn(doc), [842]);
    expect(parseLinks(out), isEmpty);
    expect(notePreviewText(out), contains('14:02 Grace'));
    expect(notePreviewText(out), isNot(contains('t:842')));
  });
}

void audioPlacementTests() {
  const two = '![A](note_audio/a.m4a)\n\n[00:05](t:5) one\n\nmiddle\n\n'
      '![B](note_audio/b.m4a)\n\n[00:09](t:9) two\n\ntail';

  test('a t: link seeks the nearest audio block above it, else the first', () {
    final doc = noteMarkdownToDocument(two);
    String name(Node? n) => n!.attributes[mediaTextKey] as String;
    expect(name(audioNodeAbove(doc, [1])), 'A');
    expect(name(audioNodeAbove(doc, [5])), 'B');
    final lead = noteMarkdownToDocument('[00:01](t:1) x\n\n![A](a.m4a)');
    expect(name(audioNodeAbove(lead, [0])), 'A');
    expect(audioNodeAbove(noteMarkdownToDocument('plain'), [0]), isNull);
  });

  test('a new take goes after the last take and its markers', () {
    expect(recordingInsertIndex(noteMarkdownToDocument('plain')), 0);
    final doc = noteMarkdownToDocument(two);
    expect(doc.root.children[recordingInsertIndex(doc) - 1].delta!.toPlainText(),
        '00:09 two');
    expect(doc.root.children[recordingInsertIndex(doc)].delta!.toPlainText(),
        'tail');
  });
}
