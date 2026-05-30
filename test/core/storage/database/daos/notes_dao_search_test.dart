import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/notes_dao.dart';

// Exercises FTS5-backed search against an in-memory database: the virtual
// table and sync triggers are created by onCreate, so insert/update/delete
// must keep results in step, and soft-deleted notes must never surface.
void main() {
  late AppDatabase db;
  late NotesDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = NotesDao(db);
  });

  tearDown(() => db.close());

  Future<void> insert(
    String id, {
    String title = '',
    String content = '',
    bool isDeleted = false,
  }) async {
    final now = DateTime.now();
    await dao.upsertNote(NotesCompanion.insert(
      id: id,
      title: Value(title),
      contentMarkdown: Value(content),
      createdAt: now,
      updatedAt: now,
      isDeleted: Value(isDeleted),
    ));
  }

  test('matches on title', () async {
    await insert('n1', title: 'Amazing Grace', content: 'how sweet');
    await insert('n2', title: 'Blessed Assurance', content: 'this is my story');

    final hits = await dao.searchNotes('amazing');
    expect(hits.map((h) => h.note.id), ['n1']);
  });

  test('matches on body content', () async {
    await insert('n1', title: 'A', content: 'the mercy of the Lord endures');
    await insert('n2', title: 'B', content: 'sing a new song');

    final hits = await dao.searchNotes('mercy');
    expect(hits.map((h) => h.note.id), ['n1']);
  });

  test('prefix-matches partial words', () async {
    await insert('n1', title: 'Redemption', content: 'bought with a price');

    final hits = await dao.searchNotes('redem');
    expect(hits.map((h) => h.note.id), ['n1']);
  });

  test('returns a snippet around the match', () async {
    await insert('n1', title: 'Grace', content: 'how sweet the sound of grace');

    final hits = await dao.searchNotes('sweet');
    expect(hits, hasLength(1));
    expect(hits.single.snippet.toLowerCase(), contains('sweet'));
  });

  test('blank query returns nothing', () async {
    await insert('n1', title: 'Grace');
    expect(await dao.searchNotes('   '), isEmpty);
  });

  test('reflects edits via the update trigger', () async {
    await insert('n1', title: 'Old Title', content: 'old body');
    expect(await dao.searchNotes('renewed'), isEmpty);

    await dao.upsertNote(NotesCompanion.insert(
      id: 'n1',
      title: const Value('Old Title'),
      contentMarkdown: const Value('renewed body'),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    final hits = await dao.searchNotes('renewed');
    expect(hits.map((h) => h.note.id), ['n1']);
  });

  test('excludes soft-deleted notes', () async {
    await insert('n1', title: 'Hidden Grace');
    await dao.softDelete('n1');

    expect(await dao.searchNotes('grace'), isEmpty);
  });
}
