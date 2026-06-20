import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/tablet/domain/tablet_markdown_codec.dart';
import 'package:openbaptisthymnal/features/tablet/domain/parse_links.dart';

void main() {
  String roundTrip(String md) =>
      noteDocumentToMarkdown(noteMarkdownToDocument(md));

  group('note markdown round-trips losslessly', () {
    const samples = <String>[
      'A plain paragraph.',
      '**bold** and _italic_ text.',
      '# Heading one',
      'Link to [[Grace]] here.',
      'Hymn [[hymn:hymn_0001]] reference.',
      'Verse [[bible:JHN.3.16]] reference.',
      'Two [[Grace]] and [[Amazing Love]] links.',
      'Mixed **bold** with a [[Grace]] link.',
    ];
    for (final sample in samples) {
      test(sample, () => expect(roundTrip(sample), sample));
    }
  });

  test('multi-block content survives and is idempotent', () {
    const multi = '# Sermon notes\n'
        '\n'
        'First paragraph with a [[Grace]] link.\n'
        '\n'
        'Second paragraph, **bold** and _italic_.';
    final once = roundTrip(multi);
    expect(roundTrip(once), once, reason: 'encode must be idempotent');
    expect(once, contains('[[Grace]]'));
    expect(once, contains('# Sermon notes'));
  });

  test('empty markdown seeds an editable blank body', () {
    final doc = noteMarkdownToDocument('');
    expect(doc.root.children, hasLength(1),
        reason: 'a blank paragraph gives the editor a body to type into');
    expect(noteDocumentToMarkdown(doc), '');
  });

  test('relative image paths round-trip untouched', () {
    // Without FileStorageService.init() the documents dir is unset, so paths
    // pass through unchanged — the relative form must survive the round-trip.
    const md = '![](note_images/abc.png)';
    expect(roundTrip(md), md);
  });

  test('audio clips (image nodes pointing at audio) round-trip untouched', () {
    const md = '![](note_audio/abc.m4a)';
    expect(roundTrip(md), md);
  });

  group('image node survives when glued to adjacent text', () {
    List<String> nodeTypes(String md) =>
        noteMarkdownToDocument(md).root.children.map((n) => n.type).toList();

    test('image followed by text on the next line keeps the image block', () {
      // This is exactly how a note was stored after recording then typing:
      // a single newline between the clip and the following paragraph. Without
      // the blank-line repair the parser folds it into one paragraph and the
      // clip vanishes ("shows the id").
      const glued = '![](note_audio/x.m4a)\ntyping after the clip';
      expect(nodeTypes(glued), contains(ImageBlockKeys.type),
          reason: 'audio clip must not disappear on reload');
    });

    test('text immediately before an image keeps the image block', () {
      const glued = 'intro line\n![](note_audio/x.m4a)';
      expect(nodeTypes(glued), contains(ImageBlockKeys.type));
    });

    test('already blank-separated content is left untouched', () {
      const clean = '![](note_audio/x.m4a)\n\ntyping after the clip';
      expect(roundTrip(clean), clean, reason: 'repair must be idempotent');
    });
  });

  test('wikilinks stay parseable by the link graph after a round-trip', () {
    const md = 'See [[Grace]], [[hymn:hymn_0001]] and [[bible:JHN.3.16]].';
    final links = parseLinks(roundTrip(md));
    expect(links.map((l) => l.type), <NoteLinkType>[
      NoteLinkType.note,
      NoteLinkType.hymn,
      NoteLinkType.bible,
    ]);
    expect(links[0].targetKey, 'Grace');
    expect(links[1].targetKey, 'hymn_0001');
    expect(links[2].targetKey, 'JHN.3.16');
  });
}
