import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/tablet/domain/note_media.dart';
import 'package:openbaptisthymnal/features/tablet/domain/note_media_actions.dart';

void main() {
  late EditorState es;
  late NoteMediaActions actions;

  List<String> texts() => es.document.root.children
      .map((n) => n.type == 'paragraph' ? n.delta!.toPlainText() : n.type)
      .toList();

  setUp(() {
    es = EditorState(
      document: Document.blank()
        ..insert([
          0
        ], [
          paragraphNode(text: 'a'),
          imageMediaNode(url: '/x.png'),
          paragraphNode(text: 'b'),
          audioMediaNode(url: '/y.m4a'),
          paragraphNode(text: 'c'),
        ]),
    );
    actions = NoteMediaActions(es);
  });

  test('move up and down reorder one slot and keep the block selected',
      () async {
    await actions.moveDown(es.getNodeAtPath([1])!);
    expect(texts(), ['a', 'b', 'image', 'audio', 'c']);
    expect(es.selection?.start.path, [2]);
    await actions.moveUp(es.getNodeAtPath([2])!);
    expect(texts(), ['a', 'image', 'b', 'audio', 'c']);
  });

  test('moveTo drops at an arbitrary slot, clamped at the ends', () async {
    await actions.moveTo(es.getNodeAtPath([1])!, 4);
    expect(texts(), ['a', 'b', 'audio', 'c', 'image']);
    await actions.moveTo(es.getNodeAtPath([4])!, -3);
    expect(texts().first, 'image');
  });

  test('delete then undo restores the block without reverting typing',
      () async {
    final removed = await actions.remove(es.getNodeAtPath([1])!);
    expect(texts(), ['a', 'b', 'audio', 'c']);
    // The user types while the undo snackbar is up.
    await es
        .apply(es.transaction..insertText(es.getNodeAtPath([0])!, 1, 'XYZ'));
    await actions.restore(removed);
    expect(texts(), ['aXYZ', 'image', 'b', 'audio', 'c']);
  });

  test('deleting the only block leaves an editable paragraph', () async {
    final solo = EditorState(
      document: Document.blank()..insert([0], [imageMediaNode(url: '/x.png')]),
    );
    await NoteMediaActions(solo).remove(solo.getNodeAtPath([0])!);
    expect(solo.document.root.children.single.type, 'paragraph');
  });

  test('attributes update in place', () async {
    final n = es.getNodeAtPath([1])!;
    await actions.setAttrs(n, {imageSizeKey: 's'});
    expect(es.getNodeAtPath([1])!.attributes[imageSizeKey], 's');
  });
}
