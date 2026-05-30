import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/note_links_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/notes_dao.dart';
import 'package:openbaptisthymnal/features/tablet/data/repositories/tablets_repository.dart';
import 'package:openbaptisthymnal/features/tablet/data/sources/local/tablets_local_source.dart';

// Exercises the notes data layer (repository -> local source -> Drift DAO)
// against an in-memory SQLite database, so create/read/update/soft-delete and
// the active-notes ordering are verified end to end.
void main() {
  late AppDatabase db;
  late TabletsRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = TabletsRepository(TabletsLocalSource(NotesDao(db), NoteLinksDao(db)));
  });

  tearDown(() => db.close());

  test('createNote persists the note and returns its id', () async {
    final id = await repo.createNote(title: 'Manna', contentMarkdown: 'daily');

    final stored = await repo.getNote(id);
    expect(stored, isNotNull);
    expect(stored!.title, 'Manna');
    expect(stored.contentMarkdown, 'daily');
    expect(stored.isDeleted, isFalse);
  });

  test('updateNote changes title and body but keeps createdAt', () async {
    final id = await repo.createNote(title: 'old', contentMarkdown: 'body');
    final created = (await repo.getNote(id))!;

    await repo.updateNote(
      id: id,
      title: 'new',
      contentMarkdown: 'rewritten',
      createdAt: created.createdAt,
    );

    final updated = (await repo.getNote(id))!;
    expect(updated.title, 'new');
    expect(updated.contentMarkdown, 'rewritten');
    expect(updated.createdAt, created.createdAt);
  });

  test('deleteNote soft-deletes: dropped from active list, row remains',
      () async {
    final id = await repo.createNote(title: 'gone');

    await repo.deleteNote(id);

    expect(await repo.watchNotes().first, isEmpty);
    final row = await repo.getNote(id);
    expect(row, isNotNull);
    expect(row!.isDeleted, isTrue);
  });

  test('watchNotes lists active notes most-recently-updated first', () async {
    // Drift persists DateTime at second resolution, so cross a full second
    // to give the two notes distinct updatedAt values.
    final first = await repo.createNote(title: 'first');
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    final second = await repo.createNote(title: 'second');

    final notes = await repo.watchNotes().first;
    expect(notes.map((n) => n.id), [second, first]);
  });
}
