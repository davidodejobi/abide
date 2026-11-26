import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';
import 'package:openbaptisthymnal/features/tablet/domain/scripture_autolink.dart';

void main() {
  final manifest = BibleManifest.fromJson(
    jsonDecode(File('assets/bible/en-kjv/manifest.json').readAsStringSync())
        as Map<String, dynamic>,
  );

  late EditorState editor;
  late ScriptureAutoLinker linker;
  late StreamSubscription<EditorTransactionValue> sub;

  setUp(() {
    editor = EditorState(document: Document.blank(withInitialText: true));
    editor.selection = Selection.collapsed(Position(path: [0], offset: 0));
    linker = ScriptureAutoLinker(editor, () => manifest);
    sub = editor.transactionStream
        .where((e) => e.$1 == TransactionTime.after)
        .listen((_) => linker.onTransaction());
  });
  tearDown(() async {
    await sub.cancel();
    editor.dispose();
  });

  String text() => editor.getNodeAtPath([0])!.delta!.toPlainText();

  // Types like a keyboard: one character per transaction, then lets the
  // linker's listener run.
  Future<void> type(String s) async {
    for (final ch in s.split('')) {
      final off = editor.selection!.startIndex;
      await editor.apply(
        editor.transaction
          ..insertText(editor.getNodeAtPath([0])!, off, ch)
          ..afterSelection =
              Selection.collapsed(Position(path: [0], offset: off + 1)),
      );
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('Given a typed reference, a space links it and keeps the caret', () async {
    await type('See John 3:16 ');
    expect(text(), 'See [[bible:JHN.3.16]] ');
    expect(editor.selection!.startIndex, text().length);
  });

  test('Given punctuation after a reference, it links too', () async {
    await type('1 Cor 13:4-7.');
    expect(text(), '[[bible:1CO.13.4-7]].');
  });

  test('Given a reference still being typed, nothing links yet', () async {
    await type('John 3:16');
    expect(text(), 'John 3:16');
    await type('-');
    expect(text(), 'John 3:16-');
    await type('18 ');
    expect(text(), '[[bible:JHN.3.16-18]] ');
  });

  test('Given an invalid reference or a time, it stays plain', () async {
    await type('John 3:99 ');
    await type('at 3:16pm ');
    expect(text(), 'John 3:99 at 3:16pm ');
  });

  test('Given a hymn number, it is not linked', () async {
    await type('Hymn 62 ');
    expect(text(), 'Hymn 62 ');
  });

  test('Given a pasted reference, it is not linked', () async {
    final node = editor.getNodeAtPath([0])!;
    await editor.apply(editor.transaction
      ..insertText(node, 0, 'John 3:16 ')
      ..afterSelection = Selection.collapsed(Position(path: [0], offset: 10)));
    await Future<void>.delayed(Duration.zero);
    expect(text(), 'John 3:16 ');
  });

  test('Given a link just made, one undo restores the plain text', () async {
    await type('John 3:16 ');
    expect(text(), '[[bible:JHN.3.16]] ');
    editor.undoManager.undo();
    await Future<void>.delayed(Duration.zero);
    expect(text(), 'John 3:16 ');
  });

  test('Given a reference already inside a token, it is left alone', () async {
    await type('[[John 3:16 ');
    expect(text(), '[[John 3:16 ');
  });
}
