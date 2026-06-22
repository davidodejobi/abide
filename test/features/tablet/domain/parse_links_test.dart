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

    test('parses a bible link with a verse range as targetKey', () {
      final link = parseLinks('see [[bible:JHN.3.16-18]]').single;
      expect(link.type, NoteLinkType.bible);
      expect(link.targetKey, 'JHN.3.16-18');
      expect(link.editionPin, isNull);
    });

    test('parses a bible link pinned to an edition', () {
      final link = parseLinks('see [[bible:JHN.3.16:en-niv]]').single;
      expect(link.type, NoteLinkType.bible);
      expect(link.targetKey, 'JHN.3.16');
      expect(link.editionPin, 'en-niv');
    });

    test('parses a hymn link pinned to a language', () {
      final link = parseLinks('sing [[hymn:hymn_0001:yo]]').single;
      expect(link.type, NoteLinkType.hymn);
      expect(link.targetKey, 'hymn_0001');
      expect(link.editionPin, 'yo');
    });

    test('lowercases the edition pin', () {
      final link = parseLinks('[[bible:JHN.3.16:EN-KJV]]').single;
      expect(link.editionPin, 'en-kjv');
    });

    test('treats numeric suffix after colon as part of the key, not a pin', () {
      // `JHN.3:16` shouldn't be misread as a pinned link of `JHN.3` to edition
      // `16` — the suffix has to look like an edition id (letters first).
      final link = parseLinks('[[bible:JHN.3:16]]').single;
      expect(link.targetKey, 'JHN.3:16');
      expect(link.editionPin, isNull);
    });

    test('dedupes pinned and unpinned variants of the same target separately',
        () {
      final links = parseLinks(
        '[[bible:JHN.3.16]] [[bible:JHN.3.16:en-kjv]] [[bible:JHN.3.16]]',
      );
      expect(links, hasLength(2));
      expect(links[0].editionPin, isNull);
      expect(links[1].editionPin, 'en-kjv');
    });
  });
}
