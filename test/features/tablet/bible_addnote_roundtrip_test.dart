import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/folders_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/note_links_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/notes_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/tags_dao.dart';
import 'package:openbaptisthymnal/features/tablet/data/sources/local/tablets_local_source.dart';
import 'package:openbaptisthymnal/features/tablet/domain/parse_links.dart';
import 'package:openbaptisthymnal/features/tablet/domain/tablet_markdown_codec.dart';

/// Guards the Bible "Add note" -> backlink bridge end to end: the exact string
/// the selection bar seeds must survive the editor's markdown<->document codec
/// and then, once saved, surface as a verse backlink (Phase C).
void main() {
  // The literal prefill `_SelectionBar.addNote` pushes into the new tablet.
  const seed = '[[bible:JHN.3.16]]\n\n';

  test('seeded bible link survives the editor codec round-trip and parses', () {
    final markdownAfterEditor =
        noteDocumentToMarkdown(noteMarkdownToDocument(seed));
    expect(markdownAfterEditor, contains('[[bible:JHN.3.16]]'),
        reason: 'wikilink must survive markdown -> document -> markdown');

    final links = parseLinks(markdownAfterEditor);
    expect(links, hasLength(1));
    expect(links.single.type, NoteLinkType.bible);
    expect(links.single.targetKey, 'JHN.3.16');
  });

  test('saving the seeded tablet surfaces a verse backlink', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final linksDao = NoteLinksDao(db);
    final source = TabletsLocalSource(
      NotesDao(db),
      linksDao,
      FoldersDao(db),
      TagsDao(db),
    );

    // Mirror the real flow: the editor saves the codec-processed markdown.
    final body = noteDocumentToMarkdown(noteMarkdownToDocument(seed));
    await source.createNote(contentMarkdown: body);

    final backlinks = await linksDao.watchBibleBacklinksForBook('JHN').first;
    expect(backlinks, hasLength(1));
    expect(backlinks.single.targetKey, 'JHN.3.16');
  });
}
