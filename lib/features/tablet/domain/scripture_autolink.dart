import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';
import 'package:openbaptisthymnal/features/tablet/domain/scripture_reference.dart';

/// Characters that end a reference when typed straight after it. `-` and `:`
/// are left out on purpose: "John 3:16" is often the start of "John 3:16-18".
const _delimiters = {' ', '.', ',', ';', ')', ']', '!', '?', '"', "'", '\n'};

/// Turns a typed reference ("John 3:16") into a `[[bible:JHN.3.16]]` token as
/// soon as a space or punctuation mark follows it. Hymn numbers are never
/// linked. The swap is one sealed history item, so a single undo brings back
/// the plain text.
class ScriptureAutoLinker {
  ScriptureAutoLinker(this.editorState, this.manifest);

  final EditorState editorState;

  /// The manifest to validate against; null while it is still loading.
  final BibleManifest? Function() manifest;

  String? _nodeId;
  int _length = 0;
  bool _busy = false;

  /// Call after every applied transaction.
  Future<void> onTransaction() async {
    // transactionStream is synchronous: it fires before the editor has moved
    // the caret and recorded undo. Wait one microtask so both have happened.
    await Future<void>.microtask(() {});
    final sel = editorState.selection;
    if (_busy || sel == null || !sel.isCollapsed) return;
    final node = editorState.getNodeAtPath(sel.start.path);
    final text = node?.delta?.toPlainText();
    if (node == null || text == null) return;

    // Only a single typed character counts: not a paste, not an undo.
    final typedOne = node.id == _nodeId && text.length == _length + 1;
    _nodeId = node.id;
    _length = text.length;

    final caret = sel.startIndex;
    final m = manifest();
    if (!typedOne || m == null || caret < 1 || caret > text.length) return;
    if (!_delimiters.contains(text[caret - 1])) return;

    final ref = scriptureReferenceAtEnd(text.substring(0, caret - 1), m);
    if (ref == null) return;

    _busy = true;
    try {
      final stack = editorState.undoManager.undoStack;
      if (stack.isNonEmpty) stack.last.seal();
      final shift = ref.token.length - ref.text.length;
      final tr = editorState.transaction
        ..replaceText(node, ref.start, ref.text.length, ref.token)
        ..afterSelection = Selection.collapsed(
          Position(path: node.path, offset: caret + shift),
        );
      await editorState.apply(tr, skipHistoryDebounce: true);
      _length = node.delta?.toPlainText().length ?? 0;
    } finally {
      _busy = false;
    }
  }
}
