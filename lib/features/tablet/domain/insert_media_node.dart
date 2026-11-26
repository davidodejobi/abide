import 'package:appflowy_editor/appflowy_editor.dart';

/// Inserts a media block ([media] is an image or audio node, see
/// note_media.dart) into the note, always followed by an empty paragraph so the
/// user has a line to keep typing in. AppFlowy's own `insertImageNode` leaves
/// the caret on the (non-editable) block with nothing after it when the block
/// lands at the end of the note, which is why we roll our own insert here.
///
/// [anchorPath] is where the caret was when the picker or recorder opened. The
/// caret ends up collapsed in the trailing paragraph.
Future<void> insertMediaNode(
  EditorState editorState,
  Node media, {
  required List<int> anchorPath,
}) async {
  final anchor = editorState.getNodeAtPath(anchorPath);
  if (anchor == null) return;

  final trailing = paragraphNode();
  final reuseEmpty = anchor.type == ParagraphBlockKeys.type &&
      (anchor.delta?.isEmpty ?? false);

  final transaction = editorState.transaction;
  if (reuseEmpty) {
    // Drop the clip where the empty paragraph sits, then remove that paragraph
    // so we don't leave a blank gap above the clip.
    transaction
      ..insertNodes(anchor.path, [media, trailing])
      ..deleteNode(anchor);
  } else {
    transaction.insertNodes(anchor.path.next, [media, trailing]);
  }

  // Trailing paragraph lands right after the audio: at the anchor's slot when
  // we reused the empty paragraph, otherwise two past the (kept) anchor.
  final caretPath = reuseEmpty ? anchor.path.next : anchor.path.next.next;
  transaction.afterSelection = Selection.collapsed(
    Position(path: caretPath, offset: 0),
  );
  await editorState.apply(transaction);
}
