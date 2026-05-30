import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/notes/domain/note_markdown_codec.dart';
import 'package:openbaptisthymnal/features/notes/domain/parse_links.dart';

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
