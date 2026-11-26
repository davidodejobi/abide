import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';
import 'package:openbaptisthymnal/features/tablet/domain/scripture_reference.dart';

void main() {
  // The real bundled manifest, so counts are the app's own.
  final manifest = BibleManifest.fromJson(
    jsonDecode(File('assets/bible/en-kjv/manifest.json').readAsStringSync())
        as Map<String, dynamic>,
  );

  List<String> keys(String text) =>
      findScriptureReferences(text, manifest).map((r) => r.targetKey).toList();

  group('Given a single verse', () {
    test('Then full names, abbreviations and spacing all resolve', () {
      expect(keys('John 3:16'), ['JHN.3.16']);
      expect(keys('Jn 3:16'), ['JHN.3.16']);
      expect(keys('Jn. 3:16'), ['JHN.3.16']);
      expect(keys('jn 3:16'), ['JHN.3.16']);
      expect(keys('John3:16'), ['JHN.3.16']);
      expect(keys('John 3 : 16'), ['JHN.3.16']);
      expect(keys('Rom 8:28'), ['ROM.8.28']);
      expect(keys('Song of Solomon 2:4'), ['SNG.2.4']);
    });

    test('Then the match covers exactly the typed reference', () {
      final r = findScriptureReferences('Read John 3:16, then rest.', manifest)
          .single;
      expect(r.text, 'John 3:16');
      expect(r.start, 5);
      expect(r.end, 14);
      expect(r.token, '[[bible:JHN.3.16]]');
    });
  });

  group('Given a range', () {
    test('Then verse ranges, en dashes and cross-chapter ranges resolve', () {
      expect(keys('1 Cor 13:4-7'), ['1CO.13.4-7']);
      expect(keys('John 3:16–18'), ['JHN.3.16-18']);
      expect(keys('John 3:16-4:2'), ['JHN.3.16-4.2']);
      expect(keys('John 3:16-16'), ['JHN.3.16']);
    });

    test('Then a backwards or out-of-range end is left as plain text', () {
      expect(keys('John 3:18-16'), isEmpty);
      expect(keys('John 3:16-99'), isEmpty);
      expect(keys('John 3:16-5:99'), isEmpty);
      expect(keys('John 3:16-2:1'), isEmpty);
    });
  });

  group('Given a whole chapter', () {
    test('Then it becomes a range over the chapter', () {
      expect(keys('Psalm 23'), ['PSA.23.1-6']);
      expect(keys('Psalms 117'), ['PSA.117.1-2']);
      expect(keys('Ps 23:1'), ['PSA.23.1']);
    });

    test('Then a chapter range spans chapters', () {
      expect(keys('John 3-4'), ['JHN.3.1-4.54']);
      expect(keys('John 4-3'), isEmpty);
    });

    test('Then a lowercase chapter-only mention stays prose', () {
      expect(keys('the job 3 times'), isEmpty);
      expect(keys('mark 5'), isEmpty);
      expect(keys('Job 3'), ['JOB.3.1-26']);
    });

    test('Then single-chapter books read the number as a verse', () {
      expect(keys('Jude 3'), ['JUD.1.3']);
      expect(keys('2 John 6'), ['2JN.1.6']);
      expect(keys('Philemon 10'), ['PHM.1.10']);
      expect(keys('Jude 99'), isEmpty);
    });
  });

  group('Given numbered books', () {
    test('Then 1 John and John 1 are different books', () {
      expect(keys('1 John 3:16'), ['1JN.3.16']);
      expect(keys('1John 1:9'), ['1JN.1.9']);
      expect(keys('John 1:1'), ['JHN.1.1']);
      expect(keys('John 1'), ['JHN.1.1-51']);
      expect(keys('1 John 1'), ['1JN.1.1-10']);
      expect(keys('2 Tim 3:16'), ['2TI.3.16']);
      expect(keys('3 John 4'), ['3JN.1.4']);
      expect(keys('1 Sam 17:45'), ['1SA.17.45']);
    });

    test('Then a stray digit before an unnumbered book is not swallowed', () {
      expect(keys('see 2 Psalm 23'), ['PSA.23.1-6']);
      // A numbered book never falls back to the unnumbered one.
      expect(keys('2 John 3:16'), isEmpty);
    });

    test('Then several references in one line are all found', () {
      expect(keys('See John 3:16, 1 John 1:9 and Psalm 23.'),
          ['JHN.3.16', '1JN.1.9', 'PSA.23.1-6']);
    });
  });

  group('Given numbered-book edge cases', () {
    test('Then a failed numbered reading is plain, never the other book', () {
      expect(keys('1 John 6:1'), isEmpty);
      expect(keys('3 John 3:16'), isEmpty);
      expect(keys('4 John 3:16'), ['JHN.3.16']); // 4 is not a prefix
    });

    test('Then roman and spelled-out prefixes work', () {
      expect(keys('I John 3:16'), ['1JN.3.16']);
      expect(keys('II John 1:5'), ['2JN.1.5']);
      expect(keys('III John 1:4'), ['3JN.1.4']);
      expect(keys('1st John 3:16'), ['1JN.3.16']);
      expect(keys('2nd Peter 1:3'), ['2PE.1.3']);
      expect(keys('First Corinthians 13:4'), ['1CO.13.4']);
      expect(keys('third john 1:4'), ['3JN.1.4']);
      expect(keys('i john 3:16'), isEmpty);
    });

    test('Then a digit that belongs to something else is not eaten', () {
      final r = findScriptureReferences('v1.2.3 John 3', manifest).single;
      expect(r.text, 'John 3');
      expect(r.targetKey, 'JHN.3.1-36');
      expect(keys('ver2 John 3:16'), ['JHN.3.16']);
    });
  });

  group('Given dot notation and URLs', () {
    test('Then John 3.16 links', () {
      expect(keys('John 3.16 '), ['JHN.3.16']);
      expect(keys('Gen 1.1 '), ['GEN.1.1']);
      expect(keys('John 3.16.'), ['JHN.3.16']);
      expect(keys('John 3.16.4'), isEmpty);
    });

    test('Then URLs and ids are left alone', () {
      expect(keys('https://www.bible.com/bible/111/JHN.3.16 '), isEmpty);
      expect(keys('https://example.com/John 3:16'), isEmpty);
      expect(keys('www.x.com/John.3.16'), isEmpty);
      expect(keys('a/John 3:16'), isEmpty);
      expect(keys('id=John 3:16'), isEmpty);
      expect(keys('user@John 3:16'), isEmpty);
    });
  });

  group('Given the bare-chapter form', () {
    test('Then only full names may use it', () {
      for (final t in ['PS 2', 'Ps 2', 'Ex 2', 'Col 3', 'Tit 2', 'Song 5',
        'Songs 5', 'Phm 3']) {
        expect(keys(t), isEmpty, reason: t);
      }
      expect(keys('Colossians 3'), ['COL.3.1-25']);
      expect(keys('Song of Solomon 5'), ['SNG.5.1-16']);
      expect(keys('Song 5:1'), ['SNG.5.1']);
    });

    test('Then it is not linked when a lowercase word follows', () {
      expect(keys('Job 3 is due'), isEmpty);
      expect(keys('Mark 5 stars'), isEmpty);
      expect(keys('Psalm 23, then'), ['PSA.23.1-6']);
      expect(keys('Psalm 23 and 1 John 1:9'), ['1JN.1.9']);
    });
  });

  group('Given text that only looks like a reference', () {
    test('Then times, unknown books and bad numbers stay plain', () {
      expect(keys('Meet at 3:16pm'), isEmpty);
      expect(keys('Jn 3:16pm'), isEmpty);
      expect(keys('John 3:16pm'), isEmpty);
      expect(keys('at 3:16'), isEmpty);
      expect(keys('Fakebook 3:16'), isEmpty);
      expect(keys('This is 5 things'), isEmpty);
      expect(keys('I am 3 years old'), isEmpty);
      expect(keys('John 99:1'), isEmpty);
      expect(keys('John 3:99'), isEmpty);
      expect(keys('John 3:0'), isEmpty);
      expect(keys('Psalm 151'), isEmpty);
      expect(keys('Johnson 3:16'), isEmpty);
      expect(keys('Abe 3:16'), isEmpty);
    });
  });

  group('Given a reference at the end of typed text', () {
    test('Then only one ending exactly there is returned', () {
      expect(scriptureReferenceAtEnd('See John 3:16', manifest)?.targetKey,
          'JHN.3.16');
      expect(scriptureReferenceAtEnd('x ' * 80 + 'John 3:16', manifest)
          ?.targetKey, 'JHN.3.16');
      expect(scriptureReferenceAtEnd('See John 3:16 and', manifest), isNull);
      expect(scriptureReferenceAtEnd('John 3:16 and Psalm 23', manifest)
          ?.targetKey, 'PSA.23.1-6');
    });

    test('Then a reference inside a wikilink is not re-linked', () {
      expect(scriptureReferenceAtEnd('[[John 3:16', manifest), isNull);
      expect(scriptureReferenceAtEnd('[[bible:JHN.3.16]] John 3:16', manifest)
          ?.targetKey, 'JHN.3.16');
    });
  });

  group('Given linkScriptureReferences', () {
    test('Then references become tokens and existing links are untouched', () {
      expect(
        linkScriptureReferences(
            'John 3:16 and [[bible:ROM.8.28]] and [[John 3:16 notes]].',
            manifest),
        '[[bible:JHN.3.16]] and [[bible:ROM.8.28]] and [[John 3:16 notes]].',
      );
    });
  });
}
