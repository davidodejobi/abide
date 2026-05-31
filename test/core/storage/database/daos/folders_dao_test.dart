import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/folders_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/notes_dao.dart';

// Exercises folder persistence against an in-memory database, including the
// reparenting safety: deleting a folder must null out folderId on its tablets
// (foreign keys are ON) so no tablet is lost or left dangling.
void main() {
  late AppDatabase db;
  late FoldersDao foldersDao;
  late NotesDao notesDao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    foldersDao = FoldersDao(db);
    notesDao = NotesDao(db);
  });

  tearDown(() => db.close());

  Future<void> addFolder(String id, String name) =>
      foldersDao.upsertFolder(FoldersCompanion.insert(id: id, name: name));

  Future<void> addNote(String id, {String? folderId}) {
    final now = DateTime.now();
    return notesDao.upsertNote(NotesCompanion.insert(
      id: id,
      folderId: Value(folderId),
      createdAt: now,
      updatedAt: now,
    ));
  }

  test('upsertFolder persists a folder that watchFolders returns', () async {
    await addFolder('f1', 'Sermons');

    final folders = await foldersDao.watchFolders().first;
    expect(folders.map((f) => f.name), ['Sermons']);
  });

  test('watchFolders lists folders alphabetically, case-insensitive', () async {
    await addFolder('f1', 'sermons');
    await addFolder('f2', 'Devotions');
    await addFolder('f3', 'Bible Study');

    final names = (await foldersDao.watchFolders().first).map((f) => f.name);
    expect(names, ['Bible Study', 'Devotions', 'sermons']);
  });

  test('upsertFolder updates the name of an existing folder', () async {
    await addFolder('f1', 'Old');
    await foldersDao
        .upsertFolder(const FoldersCompanion(id: Value('f1'), name: Value('New')));

    final folders = await foldersDao.watchFolders().first;
    expect(folders.single.name, 'New');
  });

  test('deleteFolder removes the folder', () async {
    await addFolder('f1', 'Temp');
    await foldersDao.deleteFolder('f1');

    expect(await foldersDao.watchFolders().first, isEmpty);
  });

  test('deleteFolder unassigns its tablets instead of deleting them', () async {
    await addFolder('f1', 'Sermons');
    await addNote('n1', folderId: 'f1');

    await foldersDao.deleteFolder('f1');

    final note = await notesDao.getNote('n1');
    expect(note, isNotNull);
    expect(note!.folderId, isNull);
  });
}
