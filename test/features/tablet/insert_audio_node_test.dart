import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/tablet/domain/insert_audio_node.dart';

void main() {
  List<String> types(EditorState es) =>
      es.document.root.children.map((n) => n.type).toList();

  group('insertAudioNode always leaves an editable trailing paragraph', () {
    test('cursor in a non-empty paragraph: clip + trailing inserted after it',
        () async {
      final es = EditorState(
        document: Document.blank()
          ..insert([0], [paragraphNode(text: 'intro')]),
      );
      es.selection = Selection.collapsed(Position(path: [0], offset: 5));

      await insertAudioNode(
        es,
        absoluteUrl: '/docs/note_audio/x.m4a',
        anchorPath: [0],
      );

      expect(types(es), [
        ParagraphBlockKeys.type, // intro
        ImageBlockKeys.type, // audio clip
        ParagraphBlockKeys.type, // trailing line to type in
      ]);
      // Caret sits in the trailing paragraph, ready to type.
      expect(es.selection, Selection.collapsed(Position(path: [2])));
      // The intro text is untouched.
      expect(
        es.document.nodeAtPath([0])?.delta?.toPlainText(),
        'intro',
      );
    });

    test('cursor in an empty paragraph: it is reused, no blank gap left',
        () async {
      // A blank note seeds a single empty paragraph — the common case when you
      // open a note and immediately record.
      final es = EditorState(document: Document.blank(withInitialText: true));
      es.selection = Selection.collapsed(Position(path: [0], offset: 0));

      await insertAudioNode(
        es,
        absoluteUrl: '/docs/note_audio/x.m4a',
        anchorPath: [0],
      );

      // Just the clip and the trailing line — the original empty paragraph was
      // consumed, so there is no blank line above the clip.
      expect(types(es), [
        ImageBlockKeys.type,
        ParagraphBlockKeys.type,
      ]);
      expect(es.selection, Selection.collapsed(Position(path: [1])));
    });
  });
}
