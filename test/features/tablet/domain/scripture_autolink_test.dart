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
    await type('See John 3:6 ');
    expect(text(), 'See [[bible:JHN.3.6]] ');
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
    await type('John 3:6 ');
    expect(text(), '[[bible:JHN.3.6]] ');
    editor.undoManager.undo();
    await Future<void>.delayed(Duration.zero);
    expect(text(), 'John 3:6 ');
  });

  test('Given a reference already inside a token, it is left alone', () async {
    await type('[[John 3:16 ');
    expect(text(), '[[John 3:16 ');
  });

  group('Given a verse that looks like a time', () {
    test('Then it links once the next word is not am or pm', () async {
      await type('John 3:16 ');
      expect(text(), 'John 3:16 '); // waiting
      await type('s');
      expect(text(), '[[bible:JHN.3.16]] s');
      expect(editor.selection!.startIndex, text().length);
    });

    test('Then a word starting with a or p waits for its second letter',
        () async {
      await type('John 3:16 a');
      expect(text(), 'John 3:16 a');
      await type('n');
      expect(text(), '[[bible:JHN.3.16]] an');
    });

    test('Then pm and am stay plain', () async {
      await type('Dan 5:30 pm and more');
      expect(text(), 'Dan 5:30 pm and more');
      await type('\nDan 5:30 am ok');
      expect(text(), contains('Dan 5:30 am ok'));
    });
  });

  group('Given a bare chapter', () {
    test('Then a space or a dot does not link, punctuation does', () async {
      await type('Psalm 23 ');
      expect(text(), 'Psalm 23 ');
      editor.selection = Selection.collapsed(Position(path: [0], offset: 0));
      await editor.apply(editor.transaction
        ..deleteText(editor.getNodeAtPath([0])!, 0, text().length));
      await type('Psalm 23.');
      expect(text(), 'Psalm 23.');
      await type('4 ');
      // Once the verse is typed it is a full reference and links on the space.
      expect(text(), '[[bible:PSA.23.4]] ');
    });

    test('Then a comma links it', () async {
      await type('Psalm 23,');
      expect(text(), '[[bible:PSA.23.1-6]],');
    });
  });

  test('Given dot notation, a space links it', () async {
    await type('Gen 1.1 ');
    expect(text(), '[[bible:GEN.1.1]] ');
  });

  test('Given a URL, nothing links', () async {
    await type('https://x.com/John 3:6 ');
    expect(text(), 'https://x.com/John 3:6 ');
  });

  test('Given inline code, nothing links', () async {
    final node = editor.getNodeAtPath([0])!;
    await editor.apply(editor.transaction
      ..insertText(node, 0, 'a', attributes: {'code': true})
      ..afterSelection = Selection.collapsed(Position(path: [0], offset: 1)));
    await Future<void>.delayed(Duration.zero);
    for (final ch in ' John 3:6 '.split('')) {
      final off = editor.selection!.startIndex;
      await editor.apply(editor.transaction
        ..insertText(editor.getNodeAtPath([0])!, off, ch,
            attributes: {'code': true})
        ..afterSelection =
            Selection.collapsed(Position(path: [0], offset: off + 1)));
      await Future<void>.delayed(Duration.zero);
    }
    expect(text(), 'a John 3:6 ');
  });

  test('Given Enter after a reference, the line above is linked', () async {
    await type('See John 3:6');
    final node = editor.getNodeAtPath([0])!;
    final len = text().length;
    // What Enter does: split the paragraph at the caret.
    await editor.apply(editor.transaction
      ..insertNode([1], paragraphNode())
      ..afterSelection = Selection.collapsed(Position(path: [1], offset: 0)));
    await Future<void>.delayed(Duration.zero);
    expect(node.delta!.toPlainText(), 'See [[bible:JHN.3.6]]');
    expect(len, 12);
    expect(editor.selection!.start.path, [1]);
  });
}
