import 'package:drift/drift.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/features/bible/domain/verse_ref.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_chapter.dart';

/// The only clock the tests know about.
///
/// Nothing here reads `DateTime.now()`: a test that depends on the wall clock
/// passes today and fails at midnight, or on a slow CI box. Every builder below
/// defaults its timestamps to this.
final fixedNow = DateTime(2026, 1, 15, 9, 30);

/// A tablet (note) row, ready for `notesDao.upsertNote(...)`.
///
/// Override only the field under assertion — `tabletRow(title: 'Psalm 23')` —
/// rather than restating six columns at every call site.
NotesCompanion tabletRow({
  String id = 'tablet-1',
  String title = 'Sermon notes',
  String contentMarkdown = 'The Lord is my shepherd.',
  String? folderId,
  DateTime? createdAt,
  DateTime? updatedAt,
  bool isDeleted = false,
}) {
  return NotesCompanion.insert(
    id: id,
    title: Value(title),
    contentMarkdown: Value(contentMarkdown),
    folderId: Value(folderId),
    createdAt: createdAt ?? fixedNow,
    updatedAt: updatedAt ?? fixedNow,
    isDeleted: Value(isDeleted),
  );
}

/// A folder row, ready for `foldersDao.upsertFolder(...)`.
FoldersCompanion folderRow({
  String id = 'folder-1',
  String name = 'Sermons',
}) {
  return FoldersCompanion.insert(id: id, name: name);
}

/// A single verse. Defaults to Genesis 1:1 so the ref is always valid.
Verse verse({
  String book = 'GEN',
  int chapter = 1,
  int number = 1,
  String text = 'In the beginning God created the heaven and the earth.',
}) {
  return Verse(ref: VerseRef(book, chapter, number), text: text);
}

/// A chapter. Pass [verseTexts] to control length and content in one line;
/// verse numbers are assigned 1..n so they always line up with the refs.
BibleChapter bibleChapter({
  String book = 'GEN',
  int chapter = 1,
  List<String> verseTexts = const [
    'In the beginning God created the heaven and the earth.',
    'And the earth was without form, and void.',
    'And God said, Let there be light: and there was light.',
  ],
}) {
  return BibleChapter(
    book: book,
    chapter: chapter,
    verses: [
      for (var i = 0; i < verseTexts.length; i++)
        verse(book: book, chapter: chapter, number: i + 1, text: verseTexts[i]),
    ],
  );
}
