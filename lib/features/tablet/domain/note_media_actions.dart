import 'package:appflowy_editor/appflowy_editor.dart';

/// Editor operations on a media block (image or audio). Pure appflowy, no
/// Flutter UI, so they are unit-tested against a headless [EditorState].
class NoteMediaActions {
  NoteMediaActions(this.editorState);

  final EditorState editorState;

  Future<void> setAttrs(Node node, Map<String, dynamic> attrs) =>
      editorState.apply(editorState.transaction..updateNode(node, attrs));

  /// Same as [setAttrs] but not an undo step: used for derived data such as
  /// peaks and duration measured on first play.
  Future<void> setAttrsQuietly(Node node, Map<String, dynamic> attrs) =>
      editorState.apply(
        editorState.transaction..updateNode(node, attrs),
        options: const ApplyOptions(recordUndo: false),
      );

  bool canMoveUp(Node node) => node.path.last > 0;
  bool canMoveDown(Node node) => node.next != null;

  /// Moves [node] so it ends up at sibling index [to] (index after removal).
  Future<void> moveTo(Node node, int to) async {
    final parent = node.path.sublist(0, node.path.length - 1);
    final count = node.parent?.children.length ?? 1;
    final target = to.clamp(0, count - 1);
    if (target == node.path.last) return;
    final newPath = [...parent, target];
    // Operations in one transaction are transformed against each other, so the
    // insert slot is in pre-delete coordinates: one further when moving down.
    final insertAt = [...parent, target > node.path.last ? target + 1 : target];
    final transaction = editorState.transaction
      ..moveNode(insertAt, node)
      ..afterSelection = Selection.single(
        path: newPath,
        startOffset: 0,
        endOffset: 1,
      );
    await editorState.apply(transaction);
  }

  Future<void> moveUp(Node node) => moveTo(node, node.path.last - 1);
  Future<void> moveDown(Node node) => moveTo(node, node.path.last + 1);

  /// Removes [node] and returns what [restore] needs. The file is never
  /// deleted here: the orphan sweep reclaims it later, so undo always works.
  Future<RemovedMedia> remove(Node node) async {
    final removed = RemovedMedia(node.deepCopy(), node.path, node.parent?.id);
    final transaction = editorState.transaction..deleteNode(node);
    if ((node.parent?.children.length ?? 0) <= 1) {
      transaction.insertNode(node.path, paragraphNode());
    }
    await editorState.apply(transaction);
    return removed;
  }

  /// Puts a removed block back, clamped to the document as it is now. Typing
  /// done in between is untouched because only an insert is applied.
  Future<void> restore(RemovedMedia removed) async {
    final root = editorState.document.root;
    final parentPath = removed.path.sublist(0, removed.path.length - 1);
    var parent =
        parentPath.isEmpty ? root : editorState.getNodeAtPath(parentPath);
    // The path may now point at a different node: only trust it if it is the
    // same parent as before, else fall back to the document root.
    if (parent == null || parent.id != removed.parentId) parent = root;
    final index = removed.path.last.clamp(0, parent.children.length);
    final path = [...(identical(parent, root) ? <int>[] : parentPath), index];
    await editorState
        .apply(editorState.transaction..insertNode(path, removed.node));
  }
}

class RemovedMedia {
  const RemovedMedia(this.node, this.path, this.parentId);
  final String? parentId;
  final Node node;
  final Path path;
}
