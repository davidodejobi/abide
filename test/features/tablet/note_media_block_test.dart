import 'dart:io';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/utils/services/file_storage_service.dart';
import 'package:openbaptisthymnal/features/tablet/domain/note_media.dart';
import 'package:openbaptisthymnal/features/tablet/domain/parse_links.dart';
import 'package:openbaptisthymnal/features/tablet/domain/tablet_markdown_codec.dart';
import 'package:openbaptisthymnal/features/tablet/ui/notes_strings.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/note_media_block.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/wikilink_spans.dart';

import '../../support/pump_app.dart';

void main() {
  late Directory dir;
  late File png;

  // 1x1 transparent PNG.
  final pngBytes = <int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ];

  setUp(() {
    dir = Directory.systemTemp.createTempSync('media_block');
    png = File('${dir.path}/pic.png')..writeAsBytesSync(pngBytes);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Widget editor(EditorState es, List<ParsedLink> taps) {
    final builder = NoteMediaBlockBuilder(
      editorState: es,
      storage: const FileStorageService(),
      onLink: taps.add,
    );
    return AppFlowyEditor(
      editorState: es,
      editorStyle: EditorStyle.mobile(
        textSpanDecorator: (context, node, index, text, before, after) {
          final raw = before.text ?? text.text;
          final spans = wikilinkSpans(context, raw, before.style, taps.add);
          return spans.isEmpty
              ? before
              : TextSpan(style: before.style, children: spans);
        },
      ),
      blockComponentBuilders: {
        ...standardBlockComponentBuilderMap,
        ImageBlockKeys.type: builder,
        audioNodeType: builder,
      },
    );
  }

  testWidgets('links in text and in a caption stay tappable beside media',
      (tester) async {
    File('${dir.path}/a.m4a').writeAsBytesSync([0]);
    final md = 'Read [[bible:JHN.15.1-8]] today.\n\n'
        '![Abide, see [[hymn:hymn_0062:yo]]](${png.path} "size=m")\n\n'
        '![Sermon](${dir.path}/a.m4a "dur=1000")';
    final es = EditorState(document: noteMarkdownToDocument(md));
    final taps = <ParsedLink>[];

    await tester.pumpApp(editor(es, taps));

    await tester.tapOnText(find.textRange.ofSubstring('[[bible:JHN.15.1-8]]'));
    await tester.tapOnText(find.textRange.ofSubstring('[[hymn:hymn_0062:yo]]'));

    expect(taps.map((l) => l.type), [NoteLinkType.bible, NoteLinkType.hymn]);
    expect(taps.map((l) => l.targetKey), ['JHN.15.1-8', 'hymn_0062']);
    // Audio renders compactly (64 to 72 pt) and links survive the round-trip.
    final audio = tester.getSize(find.text('Sermon').first);
    expect(audio.height, lessThan(30));
    expect(
        noteDocumentToMarkdown(es.document), contains('[[bible:JHN.15.1-8]]'));
    expect(parseLinks(noteDocumentToMarkdown(es.document)), hasLength(2));
    await tester.flushTimers();
  });

  testWidgets('a missing file shows the broken card, not a crash',
      (tester) async {
    final es = EditorState(
      document: noteMarkdownToDocument('![](${dir.path}/gone.png)'),
    );
    await tester.pumpApp(editor(es, []));
    expect(find.text(NotesStrings.fileMissing), findsOneWidget);
    expect(find.text(NotesStrings.remove), findsOneWidget);
    await tester.flushTimers();
  });

  testWidgets('the more button opens the image sheet with Size and Align',
      (tester) async {
    tester.view.physicalSize = const Size(780, 1700);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final es = EditorState(
      document: noteMarkdownToDocument('![](${png.path})'),
    );
    await tester.pumpApp(editor(es, []));
    // Let the image decode so the block has a size to hit.
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    await tester.tap(find.byTooltip(NotesStrings.mediaMore));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(NotesStrings.sizeLabel), findsOneWidget);
    expect(find.text(NotesStrings.alignLabel), findsOneWidget);
    await tester.tap(find.text(NotesStrings.sizeSmall));
    await tester.pump();
    expect(es.document.root.children.first.attributes[imageSizeKey], 's');
    await tester.flushTimers();
  });
}
