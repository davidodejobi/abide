import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/sync/in_memory_sync_remote.dart';
import 'package:openbaptisthymnal/core/sync/sync_service.dart';

DateTime t(int minutes) =>
    DateTime.utc(2026, 1, 1).add(Duration(minutes: minutes));

class Device {
  Device(InMemorySyncRemote remote, {bool Function()? enabled})
      : db = AppDatabase.forTesting(NativeDatabase.memory()) {
    service = SyncService(db: db, remote: remote, enabled: enabled);
  }

  final AppDatabase db;
  late final SyncService service;

  Future<void> writeNote(String id, String body, DateTime at,
      {String title = 't'}) {
    return db.notesDao.upsertNote(NotesCompanion.insert(
      id: id,
      title: Value(title),
      contentMarkdown: Value(body),
      createdAt: at,
      updatedAt: at,
    ));
  }

  Future<String?> body(String id) async =>
      (await db.notesDao.getNote(id))?.contentMarkdown;

  Future<int> outbox() async => (await db.select(db.syncOutbox).get()).length;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late InMemorySyncRemote remote;
  late Device a, b;

  setUp(() {
    remote = InMemorySyncRemote();
    a = Device(remote);
    b = Device(remote);
  });
  tearDown(() async {
    await a.db.close();
    await b.db.close();
  });

  group('two devices converge', () {
    test('reading progress, plans, notes and highlights flow both ways',
        () async {
      final plans = a.db.readingPlansDao;
      await plans.markReadingComplete(
        dateKey: '2026-01-02',
        source: 'plan',
        planId: 'bible-in-a-year',
        dayIndex: 2,
        completedAt: t(10),
      );
      await plans.startPlan(
          planId: 'bible-in-a-year', startDateKey: '2026-01-01');
      await a.writeNote('n1', 'hello', t(5));
      await a.db.bibleAnnotationsDao.setHighlight('JHN.3.16', 'yellow');

      await a.service.sync();
      await b.service.sync();

      expect(await b.db.readingPlansDao.completedDayKeys(), {'2026-01-02'});
      expect(
          (await b.db.readingPlansDao.activePlan())?.planId, 'bible-in-a-year');
      expect(await b.body('n1'), 'hello');
      expect(await b.db.select(b.db.planDayProgress).get(), hasLength(1));
      final hl = await b.db.select(b.db.bibleAnnotations).getSingle();
      expect(hl.verseRef, 'JHN.3.16');

      // And back: B edits, A sees it.
      await b.writeNote('n1', 'edited on b', t(50));
      await b.service.sync();
      await a.service.sync();
      expect(await a.body('n1'), 'edited on b');
    });

    test('pulled rows do not echo back into the outbox', () async {
      await a.writeNote('n1', 'x', t(1));
      await a.service.sync();
      await b.service.sync();
      expect(await b.outbox(), 0);
      expect(await a.outbox(), 0);
    });

    test('syncing twice changes nothing (idempotent)', () async {
      await a.writeNote('n1', 'x', t(1));
      await a.service.sync();
      await a.service.sync();
      await b.service.sync();
      await b.service.sync();
      expect(await b.db.select(b.db.notes).get(), hasLength(1));
      expect(await b.outbox(), 0);
    });
  });

  group('deletes propagate', () {
    test('unmarking a reading day deletes it on the other device', () async {
      final plans = a.db.readingPlansDao;
      await plans.markDayComplete(
          dateKey: '2026-01-02', source: 'plan', completedAt: t(1));
      await a.service.sync();
      await b.service.sync();
      expect(await b.db.readingPlansDao.completedDayKeys(), {'2026-01-02'});

      await plans.unmarkDay('2026-01-02');
      await a.service.sync();
      await b.service.sync();
      expect(await b.db.readingPlansDao.completedDayKeys(), isEmpty);
    });

    test('removing a highlight and soft-deleting a note propagate', () async {
      await a.db.bibleAnnotationsDao.setHighlight('ROM.8.28', 'green');
      await a.writeNote('n1', 'x', t(1));
      await a.service.sync();
      await b.service.sync();

      await a.db.bibleAnnotationsDao.removeHighlight('ROM.8.28');
      await a.db.notesDao.softDelete('n1');
      await a.service.sync();
      await b.service.sync();

      expect(await b.db.select(b.db.bibleAnnotations).get(), isEmpty);
      expect((await b.db.notesDao.getNote('n1'))!.isDeleted, isTrue);
    });

    test('a later re-mark beats an earlier delete', () async {
      final plans = a.db.readingPlansDao;
      await plans.markDayComplete(
          dateKey: '2026-01-02', source: 'plan', completedAt: t(1));
      await a.service.sync();
      await b.service.sync();
      await b.db.readingPlansDao.unmarkDay('2026-01-02');
      await b.service.sync();

      // A re-reads the day later (completedAt after the delete moment).
      await plans.markDayComplete(
          dateKey: '2026-01-02',
          source: 'plan',
          completedAt: DateTime.now().add(const Duration(hours: 1)));
      await a.service.sync();
      await b.service.sync();
      expect(await b.db.readingPlansDao.completedDayKeys(), {'2026-01-02'});
    });
  });

  group('offline then online', () {
    test('changes queue while offline and flush on reconnect', () async {
      remote.online = false;
      await a.writeNote('n1', 'offline note', t(1));
      await a.db.readingPlansDao.markDayComplete(
          dateKey: '2026-01-03', source: 'plan', completedAt: t(2));
      expect(await a.service.sync(), isFalse);
      expect(await a.outbox(), 2);
      expect(remote.get('notes', 'n1'), isNull);

      remote.online = true;
      expect(await a.service.sync(), isTrue);
      expect(await a.outbox(), 0);
      await b.service.sync();
      expect(await b.body('n1'), 'offline note');
      expect(await b.db.readingPlansDao.completedDayKeys(), {'2026-01-03'});
    });

    test('several edits while offline coalesce to the latest', () async {
      remote.online = false;
      await a.writeNote('n1', 'v1', t(1));
      await a.writeNote('n1', 'v2', t(2));
      await a.writeNote('n1', 'v3', t(3));
      await a.service.sync();
      expect(await a.outbox(), 1);
      remote.online = true;
      await a.service.sync();
      await b.service.sync();
      expect(await b.body('n1'), 'v3');
    });

    test('a failed pull leaves the cursor so nothing is skipped', () async {
      await a.writeNote('n1', 'x', t(1));
      await a.service.sync();
      remote.online = false;
      expect(await b.service.sync(), isFalse);
      remote.online = true;
      await b.service.sync();
      expect(await b.body('n1'), 'x');
    });
  });

  group('conflicts lose no data', () {
    test('newer edit wins and the older text is kept as a conflict copy',
        () async {
      await a.writeNote('n1', 'base', t(1));
      await a.service.sync();
      await b.service.sync();

      // Both edit offline; B is later.
      await a.writeNote('n1', 'from A', t(10));
      await b.writeNote('n1', 'from B', t(20));
      await b.service.sync(); // B reaches the server first
      await a.service.sync(); // A pushes stale (dropped), pulls B's

      expect(await a.body('n1'), 'from B');
      final notes = await a.db.select(a.db.notes).get();
      final copies = notes.where((n) => n.id.contains('~conflict~')).toList();
      expect(copies, hasLength(1));
      expect(copies.single.contentMarkdown, 'from A');
      expect(copies.single.title, startsWith('Conflict copy'));

      // The copy is itself synced, and everything converges.
      await a.service.sync();
      await b.service.sync();
      expect(await b.db.select(b.db.notes).get(), hasLength(2));
    });

    test('a newer local edit survives an older server copy', () async {
      await b.writeNote('n1', 'old', t(1));
      await b.service.sync();
      await a.writeNote('n1', 'new', t(30));
      await a.service.sync();
      expect(await a.body('n1'), 'new');
      await b.service.sync();
      expect(await b.body('n1'), 'new');
      expect(await b.db.select(b.db.notes).get(), hasLength(1));
    });

    test('unsynced local edit is not clobbered by pulling an older row',
        () async {
      await b.writeNote('n1', 'server old', t(1));
      await b.service.sync();
      remote.online = false;
      await a.writeNote('n1', 'local newer', t(40));
      remote.online = true;
      await a.service.sync();
      expect(await a.body('n1'), 'local newer');
      expect(remote.get('notes', 'n1')!.payload['content_markdown'],
          'local newer');
    });
  });

  group('gating and existing data', () {
    test('disabled service neither pushes nor pulls', () async {
      final off = Device(remote, enabled: () => false);
      addTearDown(off.db.close);
      await off.writeNote('n1', 'private', t(1));
      expect(await off.service.sync(), isFalse);
      expect(remote.get('notes', 'n1'), isNull);
      expect(await off.outbox(), 1);
    });

    test('pre-existing rows are queued by the upgrade backfill', () async {
      await a.writeNote('n1', 'old data', t(1));
      await a.db.customStatement('DELETE FROM sync_outbox');
      await backfillOutboxForTest(a.db);
      await a.service.sync();
      await b.service.sync();
      expect(await b.body('n1'), 'old data');
    });
  });
}

Future<void> backfillOutboxForTest(AppDatabase db) async {
  await db.customStatement(
    "INSERT OR REPLACE INTO sync_outbox(entity, row_id, op, seq, queued_at) "
    "SELECT 'notes', id, 'upsert', 1, 0 FROM notes",
  );
}
