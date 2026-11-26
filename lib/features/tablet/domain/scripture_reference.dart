import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';

/// Finds typed scripture references ("John 3:16", "1 Cor 13:4-7", "Psalm 23")
/// in plain text and validates them against a [BibleManifest] (book codes,
/// chapter counts, verse counts). Pure Dart so the note editor's auto-link and
/// the AI reference linker share one rule set.
///
/// A match becomes the `bible:` token body the app already understands, e.g.
/// `JHN.3.16`, `JHN.3.16-18`, `JHN.3.16-4.2` (see `VerseRange`). A whole
/// chapter is written as a range over its verses (`PSA.23.1-6`) because the
/// link resolver needs a verse to open on.
class ScriptureReference {
  const ScriptureReference({
    required this.start,
    required this.end,
    required this.text,
    required this.targetKey,
  });

  /// Offsets of the reference in the scanned text (end exclusive).
  final int start;
  final int end;

  /// The text as typed.
  final String text;

  /// `JHN.3.16`, `JHN.3.16-18`, `PSA.23.1-6`.
  final String targetKey;

  /// `[[bible:JHN.3.16]]`.
  String get token => '[[bible:$targetKey]]';

  @override
  String toString() => 'ScriptureReference($text -> $targetKey @ $start..$end)';
}

// USFM code -> lowercase names and abbreviations (no periods). Deliberately
// leaves out abbreviations that are everyday words ("is", "am", "act"...).
const _books = <String, String>{
  'GEN': 'genesis,gen',
  'EXO': 'exodus,exod,exo,ex',
  'LEV': 'leviticus,lev',
  'NUM': 'numbers,num',
  'DEU': 'deuteronomy,deut,deu,dt',
  'JOS': 'joshua,josh,jos',
  'JDG': 'judges,judg,jdg',
  'RUT': 'ruth,rut',
  'EZR': 'ezra,ezr',
  'NEH': 'nehemiah,neh',
  'EST': 'esther,esth,est',
  'JOB': 'job',
  'PSA': 'psalms,psalm,pslm,psa,pss,ps',
  'PRO': 'proverbs,prov,pro,prv',
  'ECC': 'ecclesiastes,eccles,eccl,ecc',
  'SNG': 'song of solomon,song of songs,song of sol,songs,song,sos',
  'ISA': 'isaiah,isa',
  'JER': 'jeremiah,jer',
  'LAM': 'lamentations,lam',
  'EZK': 'ezekiel,ezek,eze,ezk',
  'DAN': 'daniel,dan',
  'HOS': 'hosea,hos',
  'JOL': 'joel',
  'AMO': 'amos,amo',
  'OBA': 'obadiah,obad,oba',
  'JON': 'jonah,jon',
  'MIC': 'micah',
  'NAM': 'nahum,nah',
  'HAB': 'habakkuk,hab',
  'ZEP': 'zephaniah,zeph,zep',
  'HAG': 'haggai,hag',
  'ZEC': 'zechariah,zech,zec',
  'MAL': 'malachi,mal',
  'MAT': 'matthew,matt,mat,mt',
  'MRK': 'mark,mrk,mk',
  'LUK': 'luke,luk,lk',
  'JHN': 'john,jhn,jn',
  'ACT': 'acts',
  'ROM': 'romans,rom',
  'GAL': 'galatians,gal',
  'EPH': 'ephesians,eph',
  'PHP': 'philippians,phil,php',
  'COL': 'colossians,col',
  'TIT': 'titus,tit',
  'PHM': 'philemon,philem,phm',
  'HEB': 'hebrews,heb',
  'JAS': 'james,jas',
  'JUD': 'jude,jud',
  'REV': 'revelation,revelations,rev',
};

// Numbered books: (prefix digit, USFM code) pairs share the same names.
const _numbered = <(String, String, String)>[
  ('1', '1SA', 'samuel,sam'),
  ('2', '2SA', 'samuel,sam'),
  ('1', '1KI', 'kings,kgs,ki'),
  ('2', '2KI', 'kings,kgs,ki'),
  ('1', '1CH', 'chronicles,chron,chr'),
  ('2', '2CH', 'chronicles,chron,chr'),
  ('1', '1CO', 'corinthians,cor'),
  ('2', '2CO', 'corinthians,cor'),
  ('1', '1TH', 'thessalonians,thess,thes'),
  ('2', '2TH', 'thessalonians,thess,thes'),
  ('1', '1TI', 'timothy,tim'),
  ('2', '2TI', 'timothy,tim'),
  ('1', '1PE', 'peter,pet,pt'),
  ('2', '2PE', 'peter,pet,pt'),
  ('1', '1JN', 'john,jhn,jn'),
  ('2', '2JN', 'john,jhn,jn'),
  ('3', '3JN', 'john,jhn,jn'),
];

/// `'$prefix|$alias'` -> code, prefix empty for unnumbered books.
final Map<String, String> _aliasToCode = () {
  final m = <String, String>{};
  _books.forEach((code, names) {
    for (final n in names.split(',')) {
      m['|$n'] = code;
    }
  });
  for (final (prefix, code, names) in _numbered) {
    for (final n in names.split(',')) {
      m['$prefix|$n'] = code;
    }
  }
  return m;
}();

final RegExp _pattern = () {
  final names = _aliasToCode.keys.map((k) => k.split('|')[1]).toSet().toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  final alt = names
      .map((n) => RegExp.escape(n).replaceAll(' ', r'\s+'))
      .join('|');
  // 1 prefix, 2 name, 3 chapter, 4 verse, 5 end chapter (of a verse range),
  // 6 end verse, 7 end chapter (of a chapter range, "John 3-4").
  return RegExp(
    '(?<![\\p{L}\\p{N}])([123]\\s?)?($alt)\\.?\\s*(\\d{1,3})'
    r'(?:\s*:\s*(\d{1,3})(?:\s*[-–]\s*(?:(\d{1,3})\s*:\s*)?(\d{1,3}))?'
    r'|\s*[-–]\s*(\d{1,3}))?'
    r'(?![\p{L}\p{N}])(?!\s*:\s*\d)',
    caseSensitive: false,
    unicode: true,
  );
}();

/// Every valid reference in [text], in order. Anything that fails validation
/// (unknown book, chapter or verse out of range, a time such as "3:16pm")
/// is simply not returned and stays plain text.
List<ScriptureReference> findScriptureReferences(
  String text,
  BibleManifest manifest,
) {
  final books = {for (final b in manifest.books) b.code: b};
  final out = <ScriptureReference>[];
  for (final m in _pattern.allMatches(text)) {
    final prefix = m.group(1);
    final name = m.group(2)!.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    // "1 John 3:16" is 1JN; if that fails (or there is no such numbered book)
    // fall back to the unprefixed reading, so "Psalm 23" after a stray digit
    // still works.
    var code = prefix == null
        ? _aliasToCode['|$name']
        : _aliasToCode['${prefix.trim()}|$name'];
    var start = m.start;
    var ref = code == null ? null : _resolve(books[code], m, text, start);
    if (ref == null && prefix != null) {
      code = _aliasToCode['|$name'];
      start = m.start + prefix.length;
      ref = code == null ? null : _resolve(books[code], m, text, start);
    }
    if (ref != null) out.add(ref);
  }
  return out;
}

ScriptureReference? _resolve(
  BibleBookInfo? book,
  RegExpMatch m,
  String text,
  int start,
) {
  if (book == null) return null;
  final counts = book.chapterVerseCounts;
  final chapter = int.parse(m.group(3)!);
  final verseStr = m.group(4);
  final endChapterOfVerse = m.group(5);
  final endVerseStr = m.group(6);
  final endChapterOnly = m.group(7);

  // Without an explicit verse the reference is the looser "John 3" /
  // "Psalm 23" / "John 3-4" form. Require a capital first letter so a stray
  // lowercase "job 3" or "mark 5" in prose is left alone.
  final nameStart = m.start + (m.group(1)?.length ?? 0);
  final capitalised = text[nameStart] == text[nameStart].toUpperCase() &&
      text[nameStart] != text[nameStart].toLowerCase();

  String? key;
  if (verseStr == null) {
    if (!capitalised) return null;
    if (counts.length == 1 && endChapterOnly == null) {
      // Jude 3, 2 John 6, Philemon 4: the number is a verse.
      final v = chapter;
      if (v < 1 || v > counts[0]) return null;
      key = '${book.code}.1.$v';
    } else {
      final endChapter = endChapterOnly == null ? chapter : int.parse(endChapterOnly);
      if (chapter < 1 || endChapter < chapter || endChapter > counts.length) {
        return null;
      }
      final endVerse = counts[endChapter - 1];
      key = endChapter == chapter
          ? (endVerse == 1
              ? '${book.code}.$chapter.1'
              : '${book.code}.$chapter.1-$endVerse')
          : '${book.code}.$chapter.1-$endChapter.$endVerse';
    }
  } else {
    if (chapter < 1 || chapter > counts.length) return null;
    final verse = int.parse(verseStr);
    if (verse < 1 || verse > counts[chapter - 1]) return null;
    if (endVerseStr == null) {
      key = '${book.code}.$chapter.$verse';
    } else {
      final endVerse = int.parse(endVerseStr);
      final endChapter =
          endChapterOfVerse == null ? chapter : int.parse(endChapterOfVerse);
      if (endChapter < chapter || endChapter > counts.length) return null;
      if (endVerse < 1 || endVerse > counts[endChapter - 1]) return null;
      if (endChapter == chapter) {
        if (endVerse < verse) return null;
        key = endVerse == verse
            ? '${book.code}.$chapter.$verse'
            : '${book.code}.$chapter.$verse-$endVerse';
      } else {
        key = '${book.code}.$chapter.$verse-$endChapter.$endVerse';
      }
    }
  }
  return ScriptureReference(
    start: start,
    end: m.end,
    text: text.substring(start, m.end),
    targetKey: key,
  );
}

/// The reference that ends exactly at the end of [text], if any. This is what
/// the editor asks after a space or punctuation mark is typed.
ScriptureReference? scriptureReferenceAtEnd(
  String text,
  BibleManifest manifest,
) {
  final refs = findScriptureReferences(text, manifest);
  if (refs.isEmpty || refs.last.end != text.length) return null;
  final ref = refs.last;
  // Never re-link inside an existing `[[...]]` token.
  final open = text.lastIndexOf('[[', ref.start);
  if (open != -1 && !text.substring(open, ref.start).contains(']]')) {
    return null;
  }
  return ref;
}

/// Replaces every valid reference in [text] with its `[[bible:...]]` token,
/// leaving references that already sit inside a wikilink alone. For the AI
/// reference linker.
String linkScriptureReferences(String text, BibleManifest manifest) {
  final wikilinks = RegExp(r'\[\[[^\[\]]*\]\]').allMatches(text).toList();
  final buf = StringBuffer();
  var cursor = 0;
  for (final r in findScriptureReferences(text, manifest)) {
    if (r.start < cursor ||
        wikilinks.any((w) => r.start < w.end && r.end > w.start)) {
      continue;
    }
    buf
      ..write(text.substring(cursor, r.start))
      ..write(r.token);
    cursor = r.end;
  }
  return (buf..write(text.substring(cursor))).toString();
}
