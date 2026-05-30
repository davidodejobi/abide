import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/folders_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/note_links_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/notes_dao.dart';
import 'package:openbaptisthymnal/features/tablet/data/repositories/tablets_repository.dart';
import 'package:openbaptisthymnal/features/tablet/data/sources/local/tablets_local_source.dart';

// Folder organisation through the full stack: repository -> local source ->
// DAOs, against an in-memory database.
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

  test('createFolder persists a folder watchFolders returns', () async {
    final id = await repo.createFolder('Sermons');

    final folders = await repo.watchFolders().first;
    expect(folders.map((f) => f.id), [id]);
    expect(folders.single.name, 'Sermons');
  });

  test('renameFolder updates the name', () async {
    final id = await repo.createFolder('Old');
    await repo.renameFolder(id, 'New');

    expect((await repo.watchFolders().first).single.name, 'New');
  });

  test('moveNoteToFolder lists the tablet under that folder', () async {
    final folder = await repo.createFolder('Sermons');
    final note = await repo.createNote(title: 'Sunday');

    await repo.moveNoteToFolder(note, folder);

    final inFolder = await repo.watchNotesInFolder(folder).first;
    expect(inFolder.map((n) => n.id), [note]);
  });

  test('deleteFolder keeps its tablets but unfiles them', () async {
    final folder = await repo.createFolder('Sermons');
    final note = await repo.createNote(title: 'Sunday');
    await repo.moveNoteToFolder(note, folder);

    await repo.deleteFolder(folder);

    expect(await repo.watchFolders().first, isEmpty);
    final stored = await repo.getNote(note);
    expect(stored, isNotNull);
    expect(stored!.folderId, isNull);
  });
}
