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

DateTime t(int m) => DateTime.utc(2026, 1, 1).add(Duration(minutes: m));

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late InMemorySyncRemote remote;
  late FakeAuthRepository auth;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    remote = InMemorySyncRemote()..owner = 'account-1';
    auth = FakeAuthRepository(delay: Duration.zero);
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
      id: 'n1',
      contentMarkdown: const Value('mine'),
      createdAt: t(1),
      updatedAt: t(1),
    ));
  });

  test('offline: nothing is signed out or removed, and it says so', () async {
    remote.online = false;
    final saved = await container.read(signOutProvider.notifier).signOut();
    expect(saved, isFalse);
    expect((await auth.ensureAnonymousSession()).isSaved, isTrue);
    expect(await db.notesDao.getNote('n1'), isNotNull);
  });

  test('saved: signs out, wipes this reader, keeps nothing queued', () async {
    final saved = await container.read(signOutProvider.notifier).signOut();
    expect(saved, isTrue);
    expect(remote.get('notes', 'n1'), isNotNull, reason: 'synced first');
    expect((await auth.ensureAnonymousSession()).isSaved, isFalse);
    expect(await db.notesDao.getNote('n1'), isNull);
    final queue = await db.customSelect('SELECT * FROM sync_outbox').get();
    expect(queue, isEmpty);
    final state = await db.customSelect('SELECT * FROM sync_state').get();
    expect(state, isEmpty);

    // The next reader on this phone starts clean and does not inherit notes.
    remote.owner = 'anon-2';
    await container.read(syncServiceProvider)!.sync();
    expect(remote.get('notes', 'n1'), isNull);

    // Signing back in to the account brings the notes back.
    remote.owner = 'account-1';
    await container.read(syncServiceProvider)!.sync();
    expect((await db.notesDao.getNote('n1'))?.contentMarkdown, 'mine');
  });
}
