import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/folders_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/note_links_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/notes_dao.dart';
import 'package:openbaptisthymnal/features/tablet/data/repositories/tablets_repository.dart';
import 'package:openbaptisthymnal/features/tablet/data/sources/local/tablets_local_source.dart';

// Verifies that search reaches through repository -> local source -> DAO and
// reflects writes made via the repository's own create/update/delete methods.
void main() {
  late AppDatabase db;
  late TabletsRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = TabletsRepository(
      TabletsLocalSource(NotesDao(db), NoteLinksDao(db), FoldersDao(db)),
    );
  });

  tearDown(() => db.close());

  test('searchNotes finds a note created through the repository', () async {
    final id =
        await repo.createNote(title: 'Amazing Grace', contentMarkdown: 'sweet');

    final hits = await repo.searchNotes('grace');
    expect(hits.map((h) => h.note.id), [id]);
  });

  test('searchNotes reflects an update made through the repository', () async {
    final id = await repo.createNote(title: 'Draft', contentMarkdown: 'body');
    final created = (await repo.getNote(id))!;
    await repo.updateNote(
      id: id,
      title: 'Draft',
      contentMarkdown: 'pilgrimage notes',
      createdAt: created.createdAt,
    );

    expect((await repo.searchNotes('pilgrim')).map((h) => h.note.id), [id]);
  });

  test('searchNotes drops notes deleted through the repository', () async {
    final id = await repo.createNote(title: 'Temporary');
    await repo.deleteNote(id);

    expect(await repo.searchNotes('temporary'), isEmpty);
  });

  test('blank query returns no results', () async {
    await repo.createNote(title: 'Something');
    expect(await repo.searchNotes(''), isEmpty);
  });
}
