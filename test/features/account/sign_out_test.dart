import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/sync/in_memory_sync_remote.dart';
import 'package:openbaptisthymnal/core/sync/sync_providers.dart';
import 'package:openbaptisthymnal/core/sync/sync_service.dart';
import 'package:openbaptisthymnal/features/account/data/fake_auth_repository.dart';
import 'package:openbaptisthymnal/features/account/providers/account_providers.dart';

const noteId = '11111111-1111-4111-8111-111111111111';

class _ThrowingSignOut extends FakeAuthRepository {
  _ThrowingSignOut() : super(delay: Duration.zero);
  @override
  Future<void> signOut() async => throw StateError('offline');
}

DateTime t(int m) => DateTime.utc(2026, 1, 1).add(Duration(minutes: m));

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late InMemorySyncRemote remote;
  late FakeAuthRepository auth;
  FakeAuthRepository makeAuth() => FakeAuthRepository(delay: Duration.zero);
  late ProviderContainer container;

  Future<void> setUpWith(FakeAuthRepository a) async {
    auth = a;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    remote = InMemorySyncRemote()..owner = 'account-1';
    await auth.verifyCode('a@b.co', '123456');
    container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      syncServiceProvider
          .overrideWithValue(SyncService(db: db, remote: remote)),
    ]);
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    final service = container.read(syncServiceProvider)!;
    await service.sync();
    await db.notesDao.upsertNote(NotesCompanion.insert(
      id: noteId,
      contentMarkdown: const Value('mine'),
      createdAt: t(1),
      updatedAt: t(1),
    ));
    // Local-only data that never reaches the server.
    for (final q in [
      "INSERT INTO folders(id, name) VALUES ('f1', 'Sermons')",
      "INSERT INTO tags(id, name) VALUES ('t1', 'grace')",
      "INSERT INTO note_tags(note_id, tag_id) VALUES ('$noteId', 't1')",
      "INSERT INTO note_templates(id, name, icon, sections_json, created_at, "
          "updated_at) VALUES ('tp1', 'Mine', 'x', '[]', 1, 1)",
      "INSERT INTO bible_annotations(id, verse_ref, kind, inline_text, "
          "updated_at) VALUES ('vn', 'JHN.3.16', 'note', 'text', 1)",
      "INSERT INTO bible_annotations(id, verse_ref, kind, color, inline_text, "
          "updated_at) VALUES ('hl-text', 'JHN.3.17', 'highlight', 'red', 'x', 1)",
      "INSERT INTO bible_annotations(id, verse_ref, kind, color, updated_at) "
          "VALUES ('highlight:JHN.1.1', 'JHN.1.1', 'highlight', 'red', 1)",
    ]) {
      await db.customStatement(q);
    }
  }

  setUp(() => setUpWith(makeAuth()));

  Future<int> count(String table) async => (await db
          .customSelect('SELECT COUNT(*) c FROM $table')
          .getSingle())
      .read<int>('c');

  test('offline: nothing is signed out or removed, and it says so', () async {
    remote.online = false;
    final saved = await container.read(signOutProvider.notifier).signOut();
    expect(saved, isFalse);
    expect((await auth.ensureAnonymousSession()).isSaved, isTrue);
    expect(await db.notesDao.getNote(noteId), isNotNull);
  });

  test('saved: signs out, wipes this reader, keeps nothing queued', () async {
    final saved = await container.read(signOutProvider.notifier).signOut();
    expect(saved, isTrue);
    expect(remote.get('notes', noteId), isNotNull, reason: 'synced first');
    expect((await auth.ensureAnonymousSession()).isSaved, isFalse);
    expect(await db.notesDao.getNote(noteId), isNull);
    expect(await count('note_tags'), 0, reason: 'join row of a removed note');
    // Local-only data stays, the synced highlight goes.
    expect(await count('folders'), 1);
    expect(await count('tags'), 1);
    expect(await count('note_templates'), 1);
    expect(await count('bible_annotations'), 2);
    final queue = await db.customSelect('SELECT * FROM sync_outbox').get();
    expect(queue, isEmpty);
    final state = await db.customSelect('SELECT * FROM sync_state').get();
    expect(state, isEmpty);

    // The next reader on this phone starts clean and does not inherit notes.
    remote.owner = 'anon-2';
    await container.read(syncServiceProvider)!.sync();
    expect(remote.get('notes', noteId), isNull);

    // Signing back in to the account brings the notes back.
    remote.owner = 'account-1';
    await container.read(syncServiceProvider)!.sync();
    expect((await db.notesDao.getNote(noteId))?.contentMarkdown, 'mine');
  });

  test('a sync started during the lock does not repopulate wiped rows',
      () async {
    final service = container.read(syncServiceProvider)!;
    await service.flushThenLock(() async {
      await service.clearLocalData();
      remote.owner = 'anon-2'; // the next session
      expect(await service.sync(), isFalse);
    });
    expect(await db.notesDao.getNote(noteId), isNull);
    expect(await count('sync_outbox'), 0);
    expect(remote.get('notes', noteId), isNull, reason: 'not in anon-2');
    remote.owner = 'account-1';
    expect(remote.get('notes', noteId), isNotNull);
  });

  test('a signOut that throws still wipes and starts a session', () async {
    container.dispose();
    await db.close();
    final bad = _ThrowingSignOut();
    await bad.verifyCode('a@b.co', '123456');
    await setUpWith(bad);
    final saved = await container.read(signOutProvider.notifier).signOut();
    expect(saved, isTrue);
    expect(await db.notesDao.getNote(noteId), isNull);
    expect(await count('sync_outbox'), 0);
  });
}
