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
/// Special cases:
/// * a bare chapter ("Psalm 23") links on punctuation or Enter, not a space;
/// * a minutes-looking verse ("Dan 5:30") links at once like any other, but if
///   the very next word is am, pm, a.m. or p.m. the link this run just made is
///   reverted to plain text (one undoable step). A link the user typed with
///   `[[` or that was already in the note is never touched;
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

  /// The time-like link this run just made, watched for a following am/pm.
  ({int start, String original, String token})? _recent;

  /// A link just reverted, in case the "am" turns out to be "amen".
  ({int start, String original, String token})? _reverted;

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

    if (typedOne) {
      await _watchTimeSuffix(node, text);
    } else {
      _recent = null;
      _reverted = null;
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
    await _link(node, ref);
    if (ref.timeLike && delimiter == ' ') {
      _recent = (start: ref.start, original: ref.text, token: ref.token);
    }
  }

  /// After a time-like link on a space: revert it if the next word is am/pm,
  /// and bring it back if that "am" was really the start of a longer word.
  Future<void> _watchTimeSuffix(Node node, String text) async {
    final re = _reverted;
    if (re != null) {
      final end = re.start + re.original.length;
      final ok = end <= text.length &&
          text.substring(re.start, end) == re.original;
      final rest = ok ? text.substring(end).trimLeft().toLowerCase() : '';
      if (ok && RegExp(r'^[ap]m[a-z]').hasMatch(rest)) {
        _reverted = null;
        await _replace(node, re.start, re.original.length, re.token);
        return;
      }
      if (!ok || rest.length > 2) _reverted = null;
    }

    final r = _recent;
    if (r == null) return;
    final end = r.start + r.token.length;
    if (end > text.length || text.substring(r.start, end) != r.token) {
      _recent = null;
      return;
    }
    final rest = text.substring(end).trimLeft().toLowerCase();
    if (rest.isEmpty || rest == 'a' || rest == 'p' ||
        rest == 'a.' || rest == 'p.') {
      return; // still arriving
    }
    _recent = null;
    if (RegExp(r'^[ap](m|\.m)').hasMatch(rest)) {
      _reverted = r;
      await _replace(node, r.start, r.token.length, r.original);
    }
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
  }) =>
      _replace(node, ref.start, ref.text.length, ref.token,
          selection: selection);

  /// One sealed history item, so a single undo puts the old text back. The
  /// caret moves by the change in length.
  Future<void> _replace(
    Node node,
    int start,
    int length,
    String replacement, {
    Selection? selection,
  }) async {
    _busy = true;
    try {
      final stack = editorState.undoManager.undoStack;
      if (stack.isNonEmpty) stack.last.seal();
      final shift = replacement.length - length;
      final current = editorState.selection;
      final Selection after;
      if (selection != null) {
        after = selection;
      } else if (current != null && current.isCollapsed) {
        after = Selection.collapsed(Position(
          path: current.start.path,
          offset: current.startIndex + shift,
        ));
      } else {
        after = current ?? Selection.collapsed(Position(path: node.path));
      }
      final tr = editorState.transaction
        ..replaceText(node, start, length, replacement)
        ..afterSelection = after;
      await editorState.apply(tr, skipHistoryDebounce: true);
      final now = editorState.getNodeAtPath(after.start.path);
      _length = now?.delta?.toPlainText().length ?? 0;
      _node = now;
    } finally {
      _busy = false;
    }
  }
}
