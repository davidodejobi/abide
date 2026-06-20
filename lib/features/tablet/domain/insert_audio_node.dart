import 'package:appflowy_editor/appflowy_editor.dart';

/// Inserts an audio clip (an `image` node pointing at [absoluteUrl]) into the
/// note, always followed by an empty paragraph so the user has a line to keep
/// typing in. AppFlowy's own `insertImageNode` leaves the caret on the
/// (non-editable) block with nothing after it when the clip lands at the end of
/// the note, which is why we roll our own insert here.
///
/// [anchorPath] is where the caret was when recording started (falls back to
/// the last node). The caret ends up collapsed in the trailing paragraph.
Future<void> insertAudioNode(
  EditorState editorState, {
  required String absoluteUrl,
  required List<int> anchorPath,
}) async {
  final anchor = editorState.getNodeAtPath(anchorPath);
  if (anchor == null) return;

  final audio = imageNode(url: absoluteUrl);
  final trailing = paragraphNode();
  final reuseEmpty = anchor.type == ParagraphBlockKeys.type &&
      (anchor.delta?.isEmpty ?? false);

  final transaction = editorState.transaction;
  if (reuseEmpty) {
    // Drop the clip where the empty paragraph sits, then remove that paragraph
    // so we don't leave a blank gap above the clip.
    transaction
      ..insertNodes(anchor.path, [audio, trailing])
      ..deleteNode(anchor);
  } else {
    transaction.insertNodes(anchor.path.next, [audio, trailing]);
  }

  // Trailing paragraph lands right after the audio: at the anchor's slot when
  // we reused the empty paragraph, otherwise two past the (kept) anchor.
  final caretPath = reuseEmpty ? anchor.path.next : anchor.path.next.next;
  transaction.afterSelection = Selection.collapsed(
    Position(path: caretPath, offset: 0),
  );
  await editorState.apply(transaction);
}
