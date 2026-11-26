import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';
import 'package:openbaptisthymnal/features/tablet/domain/scripture_reference.dart';

/// Characters that end a reference when typed straight after it. `-` and `:`
/// are left out on purpose: "John 3:16" is often the start of "John 3:16-18".
const _delimiters = {' ', '.', ',', ';', ')', ']', '!', '?', '"', "'"};

/// Punctuation that proves a bare-chapter mention ("Psalm 23") is finished.
/// A space does not ("Job 3 is due") and neither does "." ("Psalm 23.4").
const _bareDelimiters = {',', ';', ')', ']', '!', '?', '"', "'"};

/// Turns a typed reference ("John 3:16") into a `[[bible:JHN.3.16]]` token as
/// soon as a space or punctuation mark follows it. Hymn numbers are never
/// linked. The swap is one sealed history item, so a single undo brings back
/// the plain text.
///
/// Three cases wait or skip instead of linking at once:
/// * a bare chapter ("Psalm 23") links on punctuation or Enter, not a space;
/// * minutes-looking verses ("Dan 5:30") wait for the next word, and stay
///   plain if it turns out to be am or pm;
/// * text inside inline code, URLs and existing `[[ ]]` tokens is never
///   linked.
class ScriptureAutoLinker {
  ScriptureAutoLinker(this.editorState, this.manifest);

  final EditorState editorState;

  /// The manifest to validate against; null while it is still loading.
  final BibleManifest? Function() manifest;

  Node? _node;
  int _length = 0;
  bool _busy = false;
  ScriptureReference? _pending;

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

    final previous = _node;
    final typedOne = node.id == previous?.id && text.length == _length + 1;
    final split = previous != null &&
        node.id != previous.id &&
        sel.startIndex == 0 &&
        node.previous?.id == previous.id;
    _node = node;
    _length = text.length;

    final m = manifest();
    if (m == null) return;

    if (_pending != null) {
      if (typedOne) {
        await _resolvePending(node, text);
      } else {
        _pending = null;
      }
    }

    if (split) {
      // Enter ends a reference too: check the line that was just left.
      final prevText = previous.delta?.toPlainText() ?? '';
      final ref = scriptureReferenceAtEnd(prevText, m);
      if (ref != null && !_inCode(previous, ref.end - 1)) {
        await _link(previous, ref, selection: editorState.selection);
      }
      return;
    }

    final caret = sel.startIndex;
    if (!typedOne || caret < 1 || caret > text.length) return;
    final delimiter = text[caret - 1];
    if (!_delimiters.contains(delimiter)) return;

    final ref = scriptureReferenceAtEnd(text.substring(0, caret - 1), m);
    if (ref == null || _inCode(node, ref.end - 1)) return;
    if (ref.bare && !_bareDelimiters.contains(delimiter)) return;
    if (ref.timeLike && delimiter == ' ') {
      _pending = ref;
      return;
    }
    await _link(node, ref);
  }

  /// A time-like reference followed by a space: link once the next word shows
  /// it is not "pm" / "am".
  Future<void> _resolvePending(Node node, String text) async {
    final ref = _pending!;
    if (ref.end > text.length || text.substring(ref.start, ref.end) != ref.text) {
      _pending = null;
      return;
    }
    final rest = text.substring(ref.end).trimLeft();
    if (rest.isEmpty) return; // still only spaces
    final first = rest[0].toLowerCase();
    if (first == 'a' || first == 'p') {
      if (rest.length == 1) return; // wait for the next letter
      final second = rest[1].toLowerCase();
      if (second == 'm' || second == '.') {
        _pending = null; // "5:30 pm"
        return;
      }
    }
    _pending = null;
    await _link(node, ref);
  }

  bool _inCode(Node node, int index) {
    var offset = 0;
    for (final op in node.delta?.toList() ?? const <TextOperation>[]) {
      final end = offset + op.length;
      if (index >= offset && index < end) {
        return op is TextInsert && op.attributes?['code'] == true;
      }
      offset = end;
    }
    return false;
  }

  Future<void> _link(
    Node node,
    ScriptureReference ref, {
    Selection? selection,
  }) async {
    _busy = true;
    try {
      final stack = editorState.undoManager.undoStack;
      if (stack.isNonEmpty) stack.last.seal();
      final shift = ref.token.length - ref.text.length;
      final current = editorState.selection;
      final Selection after;
      if (selection != null) {
        after = selection;
      } else if (current != null && current.isCollapsed) {
        // The caret sits after the reference (and the delimiter): keep it
        // there, moved by the length change.
        after = Selection.collapsed(Position(
          path: current.start.path,
          offset: current.startIndex + shift,
        ));
      } else {
        after = current ?? Selection.collapsed(Position(path: node.path));
      }
      final tr = editorState.transaction
        ..replaceText(node, ref.start, ref.text.length, ref.token)
        ..afterSelection = after;
      await editorState.apply(tr, skipHistoryDebounce: true);
      _length = editorState.getNodeAtPath(after.start.path)?.delta
              ?.toPlainText()
              .length ??
          0;
      _node = editorState.getNodeAtPath(after.start.path);
    } finally {
      _busy = false;
    }
  }
}
