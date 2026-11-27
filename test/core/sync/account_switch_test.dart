import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/sync/in_memory_sync_remote.dart';
import 'package:openbaptisthymnal/core/sync/sync_service.dart';

DateTime t(int m) => DateTime.utc(2026, 1, 1).add(Duration(minutes: m));

Future<void> note(AppDatabase db, String id, String body, DateTime at) =>
    db.notesDao.upsertNote(NotesCompanion.insert(
      id: id,
      contentMarkdown: Value(body),
      createdAt: at,
      updatedAt: at,
    ));

/// Signing in lands on a different user id than the anonymous one (a new phone
/// signing in to an existing account). Nothing local is lost, local rows reach
/// the account, and the account's rows arrive.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('switching account keeps local rows, pushes them, pulls the account',
      () async {
    final remote = InMemorySyncRemote();

    // The account already has a note from the reader's old phone.
    remote.owner = 'account-1';
    final old = AppDatabase.forTesting(NativeDatabase.memory());
    final oldService = SyncService(db: old, remote: remote);
    await oldService.sync();
    await note(old, 'old-note', 'from the old phone', t(1));
    await oldService.sync();
    expect(remote.get('notes', 'old-note'), isNotNull);

    // The new phone worked anonymously first.
    remote.owner = 'anon-1';
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final service = SyncService(db: db, remote: remote);
    await service.sync();
    await note(db, 'new-note', 'written before signing in', t(2));
    await service.sync();
    expect(remote.get('notes', 'new-note'), isNotNull);

    // An edit made but not yet synced when the sign-in happens.
    await note(db, 'pending-note', 'still queued', t(3));
    remote.owner = 'account-1'; // sign-in
    await service.sync();

    // Local data was never deleted.
    expect(await db.notesDao.getNote('new-note'), isNotNull);
    expect(await db.notesDao.getNote('pending-note'), isNotNull);
    // Everything local, including the pending row, now lives in the account.
    expect(remote.get('notes', 'new-note'), isNotNull);
    expect(remote.get('notes', 'pending-note'), isNotNull);
    // The account's existing row was pulled.
    expect((await db.notesDao.getNote('old-note'))?.contentMarkdown,
        'from the old phone');
    // The anonymous account is untouched.
    remote.owner = 'anon-1';
    expect(remote.get('notes', 'new-note'), isNotNull);
    expect(remote.get('notes', 'old-note'), isNull);

    await db.close();
    await old.close();
  });

  test('sign-out to a fresh anonymous user keeps local data', () async {
    final remote = InMemorySyncRemote()..owner = 'account-1';
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final service = SyncService(db: db, remote: remote);
    await service.sync();
    await note(db, 'n1', 'mine', t(1));
    await service.sync();

    remote.owner = 'anon-2';
    await service.sync();
    expect(await db.notesDao.getNote('n1'), isNotNull);
    expect(remote.get('notes', 'n1'), isNotNull, reason: 'queued into anon-2');
    await db.close();
  });
}
