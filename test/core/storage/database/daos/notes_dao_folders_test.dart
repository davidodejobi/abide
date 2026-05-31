import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/folders_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/notes_dao.dart';

// Verifies assigning/clearing a tablet's folder and the folder-filtered live
// list, against an in-memory database with foreign keys enforced.
void main() {
  late AppDatabase db;
  late NotesDao notesDao;
  late FoldersDao foldersDao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    notesDao = NotesDao(db);
    foldersDao = FoldersDao(db);
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

  test('setFolder assigns a tablet to a folder', () async {
    await addFolder('f1', 'Sermons');
    await addNote('n1');

    await notesDao.setFolder('n1', 'f1');

    expect((await notesDao.getNote('n1'))!.folderId, 'f1');
  });

  test('setFolder with null clears the folder', () async {
    await addFolder('f1', 'Sermons');
    await addNote('n1', folderId: 'f1');

    await notesDao.setFolder('n1', null);

    expect((await notesDao.getNote('n1'))!.folderId, isNull);
  });

  test('watchActiveNotesInFolder returns only that folder, newest first',
      () async {
    await addFolder('f1', 'Sermons');
    await addFolder('f2', 'Devotions');
    await addNote('a', folderId: 'f1');
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await addNote('b', folderId: 'f1');
    await addNote('c', folderId: 'f2');

    final inF1 = await notesDao.watchActiveNotesInFolder('f1').first;
    expect(inF1.map((n) => n.id), ['b', 'a']);
  });

  test('watchActiveNotesInFolder excludes soft-deleted tablets', () async {
    await addFolder('f1', 'Sermons');
    await addNote('n1', folderId: 'f1');
    await notesDao.softDelete('n1');

    expect(await notesDao.watchActiveNotesInFolder('f1').first, isEmpty);
  });
}
