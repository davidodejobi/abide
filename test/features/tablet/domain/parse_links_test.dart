import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/tablet/domain/parse_links.dart';

void main() {
  group('parseLinks', () {
    test('returns empty for markdown without tokens', () {
      expect(parseLinks('just some plain text'), isEmpty);
      expect(parseLinks(''), isEmpty);
    });

    test('parses a note link from a bare title', () {
      final links = parseLinks('see [[Sermon on the Mount]] today');
      expect(links, hasLength(1));
      expect(links.single.type, NoteLinkType.note);
      expect(links.single.targetKey, 'Sermon on the Mount');
      expect(links.single.display, 'Sermon on the Mount');
      expect(links.single.rawToken, '[[Sermon on the Mount]]');
    });

    test('parses a hymn link', () {
      final links = parseLinks('sing [[hymn:hymn_0001]]');
      expect(links.single.type, NoteLinkType.hymn);
      expect(links.single.targetKey, 'hymn_0001');
      expect(links.single.rawToken, '[[hymn:hymn_0001]]');
    });

    test('parses a bible link with OSIS ref', () {
      final links = parseLinks('read [[bible:JHN.3.16]]');
      expect(links.single.type, NoteLinkType.bible);
      expect(links.single.targetKey, 'JHN.3.16');
    });

    test('parses multiple links in order of appearance', () {
      final links = parseLinks(
        'open [[bible:JHN.3.16]] then [[hymn:hymn_0042]] and [[Notes A]]',
      );
      expect(links.map((l) => l.type).toList(), [
        NoteLinkType.bible,
        NoteLinkType.hymn,
        NoteLinkType.note,
      ]);
    });

    test('trims whitespace inside tokens', () {
      final links = parseLinks('[[  hymn:hymn_0001  ]] and [[  Title  ]]');
      expect(links[0].targetKey, 'hymn_0001');
      expect(links[1].type, NoteLinkType.note);
      expect(links[1].targetKey, 'Title');
    });

    test('case-insensitive prefix', () {
      final links = parseLinks('[[HYMN:hymn_0001]] [[Bible:JHN.3.16]]');
      expect(links[0].type, NoteLinkType.hymn);
      expect(links[1].type, NoteLinkType.bible);
    });

    test('skips empty and prefix-only tokens', () {
      expect(parseLinks('[[]] [[   ]] [[hymn:]] [[bible: ]]'), isEmpty);
    });

    test('dedupes by type and key (case-insensitive), first wins', () {
      final links = parseLinks(
        '[[Sermon]] again [[sermon]] and [[hymn:hymn_0001]] [[hymn:hymn_0001]]',
      );
      expect(links, hasLength(2));
      expect(links[0].display, 'Sermon');
      expect(links[1].type, NoteLinkType.hymn);
    });

    test('note and hymn with same key are distinct links', () {
      final links = parseLinks('[[hymn_0001]] [[hymn:hymn_0001]]');
      expect(links, hasLength(2));
      expect(links[0].type, NoteLinkType.note);
      expect(links[1].type, NoteLinkType.hymn);
    });
  });
}
