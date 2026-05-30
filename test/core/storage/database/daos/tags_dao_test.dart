import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/notes_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/tags_dao.dart';

// Exercises tag persistence and the NoteTags junction against an in-memory
// database. Covers the many-to-many wiring plus the delete safety: removing a
// tag must detach it from tablets (foreign keys are ON) without losing any.
void main() {
  late AppDatabase db;
  late TagsDao tagsDao;
  late NotesDao notesDao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tagsDao = TagsDao(db);
    notesDao = NotesDao(db);
  });

  tearDown(() => db.close());

  Future<void> addTag(String id, String name) =>
      tagsDao.upsertTag(TagsCompanion.insert(id: id, name: name));

  Future<void> addNote(String id) {
    final now = DateTime.now();
    return notesDao.upsertNote(NotesCompanion.insert(
      id: id,
      createdAt: now,
      updatedAt: now,
    ));
  }

  test('upsertTag persists a tag that watchTags returns', () async {
    await addTag('t1', 'Prayer');

    final names = (await tagsDao.watchTags().first).map((t) => t.name);
    expect(names, ['Prayer']);
  });

  test('watchTags lists tags alphabetically, case-insensitive', () async {
    await addTag('t1', 'prayer');
    await addTag('t2', 'Worship');
    await addTag('t3', 'Faith');

    final names = (await tagsDao.watchTags().first).map((t) => t.name);
    expect(names, ['Faith', 'prayer', 'Worship']);
  });

  test('upsertTag updates the name of an existing tag', () async {
    await addTag('t1', 'Old');
    await tagsDao
        .upsertTag(const TagsCompanion(id: Value('t1'), name: Value('New')));

    expect((await tagsDao.watchTags().first).single.name, 'New');
  });

  test('addTagToNote attaches a tag the note then carries', () async {
    await addNote('n1');
    await addTag('t1', 'Prayer');

    await tagsDao.addTagToNote('n1', 't1');

    final tags = await tagsDao.watchTagsForNote('n1').first;
    expect(tags.map((t) => t.id), ['t1']);
  });

  test('addTagToNote is idempotent for an already-attached tag', () async {
    await addNote('n1');
    await addTag('t1', 'Prayer');

    await tagsDao.addTagToNote('n1', 't1');
    await tagsDao.addTagToNote('n1', 't1');

    expect((await tagsDao.watchTagsForNote('n1').first).length, 1);
  });

  test('removeTagFromNote detaches the tag but keeps both rows', () async {
    await addNote('n1');
    await addTag('t1', 'Prayer');
    await tagsDao.addTagToNote('n1', 't1');

    await tagsDao.removeTagFromNote('n1', 't1');

    expect(await tagsDao.watchTagsForNote('n1').first, isEmpty);
    expect((await tagsDao.watchTags().first).single.id, 't1');
  });

  test('watchActiveNotesWithTag returns only tagged tablets, newest first',
      () async {
    await addTag('t1', 'Prayer');
    await addNote('older');
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await addNote('newer');
    await addNote('untagged');
    await tagsDao.addTagToNote('older', 't1');
    await tagsDao.addTagToNote('newer', 't1');

    final ids =
        (await tagsDao.watchActiveNotesWithTag('t1').first).map((n) => n.id);
    expect(ids, ['newer', 'older']);
  });

  test('watchActiveNotesWithTag excludes soft-deleted tablets', () async {
    await addTag('t1', 'Prayer');
    await addNote('n1');
    await tagsDao.addTagToNote('n1', 't1');

    await notesDao.softDelete('n1');

    expect(await tagsDao.watchActiveNotesWithTag('t1').first, isEmpty);
  });

  test('deleteTag removes the tag and detaches it from its tablets', () async {
    await addNote('n1');
    await addTag('t1', 'Prayer');
    await tagsDao.addTagToNote('n1', 't1');

    await tagsDao.deleteTag('t1');

    expect(await tagsDao.watchTags().first, isEmpty);
    expect(await tagsDao.watchTagsForNote('n1').first, isEmpty);
    final note = await notesDao.getNote('n1');
    expect(note, isNotNull);
  });
}
