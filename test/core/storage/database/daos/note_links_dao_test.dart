import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/note_links_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/notes_dao.dart';

void main() {
  late AppDatabase db;
  late NotesDao notesDao;
  late NoteLinksDao linksDao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    notesDao = NotesDao(db);
    linksDao = NoteLinksDao(db);
  });

  tearDown(() => db.close());

  Future<String> insertNote({
    required String id,
    String title = '',
    bool isDeleted = false,
  }) async {
    final now = DateTime.now();
    await notesDao.upsertNote(NotesCompanion.insert(
      id: id,
      title: Value(title),
      createdAt: now,
      updatedAt: now,
      isDeleted: Value(isDeleted),
    ));
    return id;
  }

  NoteLinksCompanion link(String source, String type, String key) =>
      NoteLinksCompanion.insert(
        id: '$source-$type-$key',
        sourceNoteId: source,
        targetType: type,
        targetKey: key,
        rawToken: '[[$key]]',
      );

  test('replaceLinksForNote inserts the outgoing set', () async {
    await insertNote(id: 'n1');
    await linksDao.replaceLinksForNote('n1', [
      link('n1', 'hymn', 'hymn_0001'),
      link('n1', 'note', 'Sermon'),
    ]);

    final out = await linksDao.watchOutgoing('n1').first;
    expect(out, hasLength(2));
    expect(out.map((l) => l.targetKey), containsAll(['hymn_0001', 'Sermon']));
  });

  test('replaceLinksForNote replaces previous links', () async {
    await insertNote(id: 'n1');
    await linksDao.replaceLinksForNote('n1', [link('n1', 'hymn', 'hymn_0001')]);
    await linksDao.replaceLinksForNote('n1', [link('n1', 'bible', 'JHN.3.16')]);

    final out = await linksDao.watchOutgoing('n1').first;
    expect(out, hasLength(1));
    expect(out.single.targetType, 'bible');
  });

  test('replaceLinksForNote with empty list clears links', () async {
    await insertNote(id: 'n1');
    await linksDao.replaceLinksForNote('n1', [link('n1', 'note', 'X')]);
    await linksDao.replaceLinksForNote('n1', []);

    expect(await linksDao.watchOutgoing('n1').first, isEmpty);
  });

  test('watchBacklinks returns notes linking to a title, case-insensitive',
      () async {
    await insertNote(id: 'target', title: 'Grace');
    await insertNote(id: 'src1', title: 'Source One');
    await insertNote(id: 'src2', title: 'Source Two');
    await linksDao.replaceLinksForNote('src1', [link('src1', 'note', 'grace')]);
    await linksDao.replaceLinksForNote('src2', [link('src2', 'note', 'Grace')]);

    final backlinks = await linksDao.watchBacklinks('Grace').first;
    expect(backlinks.map((n) => n.id), containsAll(['src1', 'src2']));
  });

  test('watchBacklinks excludes deleted source notes', () async {
    await insertNote(id: 'target', title: 'Grace');
    await insertNote(id: 'src', title: 'Gone', isDeleted: true);
    await linksDao.replaceLinksForNote('src', [link('src', 'note', 'Grace')]);

    expect(await linksDao.watchBacklinks('Grace').first, isEmpty);
  });

  test('watchBacklinks ignores non-note link types', () async {
    await insertNote(id: 'src', title: 'Source');
    await linksDao
        .replaceLinksForNote('src', [link('src', 'hymn', 'hymn_0001')]);

    expect(await linksDao.watchBacklinks('hymn_0001').first, isEmpty);
  });
}
