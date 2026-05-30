import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/folders_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/note_links_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/notes_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/tags_dao.dart';
import 'package:openbaptisthymnal/features/tablet/data/repositories/tablets_repository.dart';
import 'package:openbaptisthymnal/features/tablet/data/sources/local/tablets_local_source.dart';

// Tag organisation through the full stack: repository -> local source -> DAOs,
// against an in-memory database. Covers the many-to-many wiring and the
// delete-detaches-but-keeps-tablets safety.
void main() {
  late AppDatabase db;
  late TabletsRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = TabletsRepository(
      TabletsLocalSource(
        NotesDao(db),
        NoteLinksDao(db),
        FoldersDao(db),
        TagsDao(db),
      ),
    );
  });

  tearDown(() => db.close());

  test('createTag persists a tag watchTags returns', () async {
    final id = await repo.createTag('Prayer');

    final tags = await repo.watchTags().first;
    expect(tags.map((t) => t.id), [id]);
    expect(tags.single.name, 'Prayer');
  });

  test('renameTag updates the name', () async {
    final id = await repo.createTag('Old');
    await repo.renameTag(id, 'New');

    expect((await repo.watchTags().first).single.name, 'New');
  });

  test('addTagToNote lists the tag on the tablet and vice versa', () async {
    final tag = await repo.createTag('Prayer');
    final note = await repo.createNote(title: 'Sunday');

    await repo.addTagToNote(note, tag);

    expect((await repo.watchTagsForNote(note).first).map((t) => t.id), [tag]);
    expect((await repo.watchNotesWithTag(tag).first).map((n) => n.id), [note]);
  });

  test('removeTagFromNote detaches the tag', () async {
    final tag = await repo.createTag('Prayer');
    final note = await repo.createNote(title: 'Sunday');
    await repo.addTagToNote(note, tag);

    await repo.removeTagFromNote(note, tag);

    expect(await repo.watchTagsForNote(note).first, isEmpty);
    expect(await repo.watchNotesWithTag(tag).first, isEmpty);
  });

  test('deleteTag keeps its tablets but detaches them', () async {
    final tag = await repo.createTag('Prayer');
    final note = await repo.createNote(title: 'Sunday');
    await repo.addTagToNote(note, tag);

    await repo.deleteTag(tag);

    expect(await repo.watchTags().first, isEmpty);
    expect(await repo.getNote(note), isNotNull);
    expect(await repo.watchTagsForNote(note).first, isEmpty);
  });
}
