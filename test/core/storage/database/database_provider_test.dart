import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/bible_annotations_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/folders_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/note_links_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/notes_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/reading_plans_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/tags_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/database_provider.dart';

/// The DAO providers had no test at all -- not the new one, not the five that
/// shipped before it.
///
/// The thing worth asserting is not the type (the compiler already guarantees
/// that) but the *wiring*: every DAO must hang off the one app database. A DAO
/// that quietly built its own connection would pass the analyzer, pass every
/// DAO test (they construct the DAO directly), and then write to a database
/// nothing else reads -- notes that save and vanish.
void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      // The real appDatabaseProvider opens a file through path_provider, which
      // has no implementation in a unit test. Overriding it is also what makes
      // the "same instance" assertion below meaningful.
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() {
    container.dispose();
    db.close();
  });

  group('Given the app database', () {
    group('When a DAO is read from its provider', () {
      test('Then every DAO is attached to that one database', () {
        final daos = <String, DatabaseAccessor<AppDatabase>>{
          'notes': container.read(notesDaoProvider),
          'noteLinks': container.read(noteLinksDaoProvider),
          'folders': container.read(foldersDaoProvider),
          'tags': container.read(tagsDaoProvider),
          'bibleAnnotations': container.read(bibleAnnotationsDaoProvider),
          'readingPlans': container.read(readingPlansDaoProvider),
        };

        for (final entry in daos.entries) {
          expect(
            entry.value.attachedDatabase,
            same(db),
            reason: '${entry.key} DAO must use the shared database, not its own',
          );
        }
      });

      test('Then each provider yields its own DAO type', () {
        expect(container.read(notesDaoProvider), isA<NotesDao>());
        expect(container.read(noteLinksDaoProvider), isA<NoteLinksDao>());
        expect(container.read(foldersDaoProvider), isA<FoldersDao>());
        expect(container.read(tagsDaoProvider), isA<TagsDao>());
        expect(
          container.read(bibleAnnotationsDaoProvider),
          isA<BibleAnnotationsDao>(),
        );
        expect(container.read(readingPlansDaoProvider), isA<ReadingPlansDao>());
      });
    });

    group('When the same DAO provider is read twice', () {
      test('Then it is the same instance, not a new one each read', () {
        // These are plain Providers, so they cache. If one were rebuilt per
        // read, every widget watching it would get a fresh DAO and its streams
        // would resubscribe on every rebuild.
        expect(
          container.read(readingPlansDaoProvider),
          same(container.read(readingPlansDaoProvider)),
        );
      });
    });
  });

  group('Given a DAO obtained through its provider', () {
    group('When it writes', () {
      test('Then the write lands in the shared database', () async {
        // Closes the loop: proves the provider chain is not just type-correct
        // but actually usable end to end.
        final dao = container.read(readingPlansDaoProvider);

        await dao.markDayComplete(
          dateKey: '2026-01-15',
          source: 'plan',
          completedAt: DateTime(2026, 1, 15, 9, 30),
        );

        final rows = await db.select(db.readingDays).get();
        expect(rows.single.dateKey, '2026-01-15');
      });
    });
  });
}
