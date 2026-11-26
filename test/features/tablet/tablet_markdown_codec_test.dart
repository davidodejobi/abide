import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/tablet/domain/tablet_markdown_codec.dart';
import 'package:openbaptisthymnal/features/tablet/domain/note_media.dart';
import 'package:openbaptisthymnal/features/tablet/domain/parse_links.dart';

void main() {
  // A one-image document whose caption is [caption].
  Document noteDocumentToDoc(String caption) => Document.blank()
    ..insert([0], [imageMediaNode(url: 'note_images/x.png', caption: caption)]);

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
      expect(nodeTypes(glued), contains(audioNodeType),
          reason: 'audio clip must not disappear on reload');
    });

    test('text immediately before an image keeps the image block', () {
      const glued = 'intro line\n![](note_audio/x.m4a)';
      expect(nodeTypes(glued), contains(audioNodeType));
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

  group('media attributes', () {
    const peaks = '0a1f3c';
    const samples = <String>[
      '![](note_images/x.png "size=m")',
      '![](note_images/x.png "size=s align=left")',
      '![A caption](note_images/x.png "align=left")',
      '![Recording\\, 26 Nov](note_audio/x.m4a "dur=135000 speed=150 peaks=$peaks")',
      '![](note_audio/x.m4a "dur=1000")',
      r'![a \[ lone bracket and \\ slash](note_images/x.png)',
      r'![a \) paren and \" quote](note_images/x.png "size=m")',
    ];
    for (final s in samples) {
      test(s, () => expect(roundTrip(s), s));
    }

    test('captions with markdown punctuation stay literal text', () {
      const captions = [
        'see `code` here',
        'a *b* c',
        '2*3*4',
        'Tom &amp; Jerry',
        '~~s~~',
        '<http://x.y>',
        'link [x](http://a.b)',
        '![nested](x.png)',
        'Abide [[bible:JHN.3.16]] and [[hymn:hymn_0062:yo]]',
        'Recording, 26 Nov, 10:42',
      ];
      for (final c in captions) {
        final doc = noteDocumentToDoc(c);
        expect(doc.root.children, hasLength(1), reason: c);
        final node = doc.root.children.single;
        expect(node.type, ImageBlockKeys.type, reason: c);
        expect(node.attributes[mediaTextKey], c, reason: c);
        // And the same text survives a second encode.
        final md = noteDocumentToMarkdown(doc);
        expect(roundTrip(md), md, reason: c);
        // Audio names use the same escaping.
        final audio = Document.blank()
          ..insert([0], [audioMediaNode(url: 'note_audio/a.m4a', name: c)]);
        final back = noteMarkdownToDocument(noteDocumentToMarkdown(audio));
        expect(back.root.children.single.attributes[mediaTextKey], c,
            reason: c);
      }
      // [[...]] stays verbatim in the stored line.
      final doc = noteDocumentToDoc('Abide [[bible:JHN.3.16]]');
      expect(noteDocumentToMarkdown(doc), contains('[[bible:JHN.3.16]]'));
    });

    test('encodePeaks ignores NaN and infinity', () {
      expect(() => encodePeaks([double.nan, 0.5, double.infinity, -0.2]),
          returnsNormally);
      expect(encodePeaks([double.nan, double.infinity]), '');
    });

    test('attributes land on the nodes', () {
      final doc = noteMarkdownToDocument(
          '![Hi](note_audio/x.m4a "dur=5 speed=150 peaks=ff00")\n\n'
          '![Cap](note_images/y.png "size=s align=left")');
      final audio = doc.root.children[0];
      expect(audio.type, audioNodeType);
      expect(audio.attributes[mediaTextKey], 'Hi');
      expect(audio.attributes[audioDurationKey], 5);
      expect(audio.attributes[audioSpeedKey], 150);
      expect(audio.attributes[audioPeaksKey], 'ff00');
      final image = doc.root.children[1];
      expect(image.type, ImageBlockKeys.type);
      expect(image.attributes[imageSizeKey], 's');
      expect(image.attributes[imageAlignKey], 'left');
    });

    test('legacy media is byte-identical, defaults stay omitted', () {
      const legacy =
          'intro\n\n![](note_images/a.png)\n\n![](note_audio/b.m4a)\n\nend';
      expect(roundTrip(legacy), legacy);
    });

    test('peaks quantise to 48 bars and decode back', () {
      final hex = encodePeaks(List.generate(500, (i) => (i % 50) / 50));
      expect(hex.length, peakBars * 2);
      expect(decodePeaks(hex), hasLength(peakBars));
    });
  });

  test('links around and inside media survive and stay parseable', () {
    const md = 'Read [[bible:JHN.15.1-8]] and [[hymn:hymn_0062:yo]].\n\n'
        '![Abide\\, see [[bible:JHN.15.4]]](note_images/x.png "size=m")\n\n'
        '![Sermon](note_audio/x.m4a "dur=10")\n\n'
        'Then [[Grace]].';
    final out = roundTrip(md);
    expect(out, md);
    final keys = parseLinks(out).map((l) => l.targetKey).toList();
    expect(keys, ['JHN.15.1-8', 'hymn_0062', 'JHN.15.4', 'Grace']);
    // Caption text keeps the token so the tappable renderer can find it.
    final image = noteMarkdownToDocument(md).root.children[1];
    expect(image.attributes[mediaTextKey], contains('[[bible:JHN.15.4]]'));
  });
}
