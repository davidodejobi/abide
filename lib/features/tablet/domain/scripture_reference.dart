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
    this.bare = false,
    this.timeLike = false,
  });

  /// Offsets of the reference in the scanned text (end exclusive).
  final int start;
  final int end;

  /// The text as typed.
  final String text;

  /// `JHN.3.16`, `JHN.3.16-18`, `PSA.23.1-6`.
  final String targetKey;

  /// A whole-chapter mention without a verse ("Psalm 23", "Jude 3"). Easy to
  /// mistake for prose, so the editor only links these on real punctuation.
  final bool bare;

  /// Ends in minutes-looking digits ("Dan 5:30"): the user may be mid-way
  /// through typing a time ("5:30 pm"), so the editor waits for the next word.
  final bool timeLike;

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

/// Names written out in full. Only these may use the bare-chapter form
/// ("Psalm 23"); abbreviations ("Ps 2", "Col 3", "Ex 2") need a verse.
final Set<String> _fullNames = {
  for (final names in _books.values) names.split(',').first,
  for (final (_, _, names) in _numbered) names.split(',').first,
  'psalm', 'revelations', 'song of songs', //
};

/// Names that also exist as a numbered book (john, samuel, ...). A failed
/// numbered reading never falls back to the unnumbered book for these.
final Set<String> _numberedNames = {
  for (final (_, _, names) in _numbered) ...names.split(','),
};

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
  final alt =
      names.map((n) => RegExp.escape(n).replaceAll(' ', r'\s+')).join('|');
  // 1 prefix, 2 name, 3 chapter, 4 verse, 5 end chapter (of a verse range),
  // 6 end verse, 7 end chapter (of a chapter range, "John 3-4").
  // Chapter and verse may be split by ":" or "." ("John 3.16"). The start may
  // not follow a letter, digit or one of / . : _ = # @ (URLs, versions, ids).
  return RegExp(
    r'(?<![\p{L}\p{N}/.:_=#@])'
    r'((?:1st|2nd|3rd|first|second|third)\s+|[123]\s?|I{1,3}\s+)?'
    '($alt)\\.?\\s*(\\d{1,3})'
    r'(?:(?:\s*:\s*|\.)(\d{1,3})(?:\s*[-–]\s*(?:(\d{1,3})\s*:\s*)?(\d{1,3}))?'
    r'|\s*[-–]\s*(\d{1,3}))?'
    r'(?![\p{L}\p{N}])(?!\s*:\s*\d)(?!\.\d)',
    caseSensitive: false,
    unicode: true,
  );
}();

final _timeTail = RegExp(r'(?:^|\D)\d{1,2}\s*:\s*[0-5]\d$');

/// "1st"/"first"/"I"/"1" -> "1" (null when not a recognised prefix).
String? _prefixDigit(String raw, String text) {
  final p = raw.trim().toLowerCase();
  if (p.isEmpty) return null;
  if (RegExp(r'^[123]').hasMatch(p)) return p[0];
  if (RegExp(r'^i{1,3}$').hasMatch(p)) {
    // Roman numerals only when typed as capitals: "I John", not "i john".
    return raw.trim() == raw.trim().toUpperCase() ? '${p.length}' : null;
  }
  return switch (p) {
    'first' => '1',
    'second' => '2',
    'third' => '3',
    _ => null,
  };
}

/// Every valid reference in [text], in order. Anything that fails validation
/// (unknown book, chapter or verse out of range, a time such as "3:16pm",
/// a URL) is simply not returned and stays plain text.
List<ScriptureReference> findScriptureReferences(
  String text,
  BibleManifest manifest,
) {
  final books = {for (final b in manifest.books) b.code: b};
  final out = <ScriptureReference>[];
  for (final m in _pattern.allMatches(text)) {
    if (_inUrl(text, m.start)) continue;
    final prefixRaw = m.group(1);
    final name = m.group(2)!.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final digit = prefixRaw == null ? null : _prefixDigit(prefixRaw, text);

    ScriptureReference? ref;
    if (prefixRaw == null) {
      final code = _aliasToCode['|$name'];
      if (code != null) ref = _resolve(books[code], m, text, m.start, name);
    } else {
      final code = digit == null ? null : _aliasToCode['$digit|$name'];
      if (code != null) {
        // A numbered book either reads as that book or not at all: "1 John
        // 6:1" is never John.
        ref = _resolve(books[code], m, text, m.start, name);
      } else if (!_numberedNames.contains(name)) {
        // "see 2 Psalm 23": the digit was not a prefix.
        final unprefixed = _aliasToCode['|$name'];
        if (unprefixed != null) {
          ref = _resolve(books[unprefixed], m, text,
              m.start + prefixRaw.length, name);
        }
      }
    }
    if (ref != null) out.add(ref);
  }
  return out;
}

bool _inUrl(String text, int at) {
  var a = at;
  while (a > 0 && !RegExp(r'\s').hasMatch(text[a - 1])) {
    a--;
  }
  var b = at;
  while (b < text.length && !RegExp(r'\s').hasMatch(text[b])) {
    b++;
  }
  final word = text.substring(a, b).toLowerCase();
  return word.contains('://') || word.contains('www.');
}

ScriptureReference? _resolve(
  BibleBookInfo? book,
  RegExpMatch m,
  String text,
  int start,
  String name,
) {
  if (book == null) return null;
  final counts = book.chapterVerseCounts;
  final chapter = int.parse(m.group(3)!);
  final verseStr = m.group(4);
  final endChapterOfVerse = m.group(5);
  final endVerseStr = m.group(6);
  final endChapterOnly = m.group(7);

  String? key;
  var bare = false;
  if (verseStr == null) {
    bare = true;
    // The loose "John 3" / "Psalm 23" / "Jude 3" form: a full book name, a
    // capital letter, and not followed by a lowercase word ("Job 3 is due",
    // "Mark 5 stars"). Abbreviations such as "Ps 2" or "Col 3" need a verse.
    if (!_fullNames.contains(name)) return null;
    final nameStart = m.start + (m.group(1)?.length ?? 0);
    final ch = text[nameStart];
    if (ch == ch.toLowerCase()) return null;
    if (_followedByLowercaseWord(text, m.end)) return null;
    if (counts.length == 1 && endChapterOnly == null) {
      // Jude 3, 2 John 6, Philemon 4: the number is a verse.
      final v = chapter;
      if (v < 1 || v > counts[0]) return null;
      key = '${book.code}.1.$v';
    } else {
      final endChapter =
          endChapterOnly == null ? chapter : int.parse(endChapterOnly);
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
    // "John 3.16" is dot notation only for a capitalised name; "gen 2.3" or
    // "mark 2.5 percent" in prose is not a reference. A colon works in any case.
    final nameStart = m.start + (m.group(1)?.length ?? 0);
    if (RegExp(r'^\D*\d{1,3}\.\d').hasMatch(text.substring(nameStart, m.end))) {
      final ch = text[nameStart];
      if (ch == ch.toLowerCase()) return null;
    }
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
  final matched = text.substring(start, m.end);
  return ScriptureReference(
    start: start,
    end: m.end,
    text: matched,
    targetKey: key,
    bare: bare,
    timeLike: !bare && endVerseStr == null && _timeTail.hasMatch(matched),
  );
}

bool _followedByLowercaseWord(String text, int end) {
  var i = end;
  while (i < text.length && (text[i] == ' ' || text[i] == '\t')) {
    i++;
  }
  if (i >= text.length) return false;
  final ch = text[i];
  return ch != ch.toUpperCase() && ch == ch.toLowerCase() &&
      RegExp(r'\p{L}', unicode: true).hasMatch(ch);
}

/// The reference that ends exactly at the end of [text], if any. This is what
/// the editor asks after a space or punctuation mark is typed. Only the last
/// ~60 characters are scanned.
ScriptureReference? scriptureReferenceAtEnd(
  String text,
  BibleManifest manifest,
) {
  var base = 0;
  if (text.length > 60) {
    // Start after a space so a cut never lands inside a word.
    final sp = text.indexOf(' ', text.length - 60);
    if (sp == -1) return null;
    base = sp + 1;
  }
  final refs = findScriptureReferences(text.substring(base), manifest);
  if (refs.isEmpty || refs.last.end != text.length - base) return null;
  final r = refs.last;
  final ref = ScriptureReference(
    start: r.start + base,
    end: r.end + base,
    text: r.text,
    targetKey: r.targetKey,
    bare: r.bare,
    timeLike: r.timeLike,
  );
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
