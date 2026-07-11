import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';

import '../../../drift_schemas/schema.dart';
import '../../../drift_schemas/schema_v1.dart' as v1;
import '../../../drift_schemas/schema_v3.dart' as v3;
import '../../../drift_schemas/schema_v4.dart' as v4;

/// Migration tests for [AppDatabase].
///
/// These exist because every other database test builds a *fresh* database:
/// `AppDatabase.forTesting` runs `onCreate`/`createAll` and never touches
/// `onUpgrade`. That leaves the upgrade path — the one every existing user
/// actually takes — completely unexercised. [SchemaVerifier] fixes that by
/// building a database at an old schema version, running the real migration,
/// and diffing the result against the expected schema.
void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  // Derived, not hardcoded, so this file does not quietly keep testing a stale
  // target after the next schema bump. The guard test at the bottom ties
  // GeneratedHelper.versions back to the live schemaVersion, so if someone bumps
  // the version without dumping a snapshot, that fails rather than this silently
  // validating against the old one.
  final current = GeneratedHelper.versions.last;
  final older = GeneratedHelper.versions.where((v) => v < current);

  group('Given a database created at an older schema version', () {
    // EVERY version users could still be sitting on, not just the newest hop.
    // Someone who last opened the app months ago upgrades straight from v1, and
    // that path is exactly the one nobody thinks to check.
    for (final from in older) {
      group('When the current app opens it', () {
        test('Then v$from migrates to v$current and the schema matches',
            () async {
          final connection = await verifier.startAt(from);
          final db = AppDatabase.forTesting(connection);
          // Registered before the assertion: migrateAndValidate throws on a bad
          // migration, and a bare close() after it would be skipped, leaking the
          // native connection into the next test.
          addTearDown(db.close);

          // Runs the real onUpgrade, then compares the resulting schema against
          // the reference. A migration branch that forgets a createTable fails
          // here rather than on a user's phone.
          await verifier.migrateAndValidate(db, current);
        });
      });
    }
  });

  group('Given a v1 database holding real user data', () {
    group('When it migrates to the current version', () {
      test('Then notes and highlights survive, and search is backfilled',
          () async {
        // The longest upgrade path in the wild: someone who installed at v1 and
        // has not opened the app since. Schema correctness is not the same as
        // data survival, so this seeds real rows and reads them back.
        //
        // Fixed timestamps: the assertions below compare them exactly.
        final createdAt = DateTime.utc(2026, 1, 15, 9, 30);

        await verifier.testWithDataIntegrity(
          oldVersion: 1,
          newVersion: 4,
          createOld: v1.DatabaseAtV1.new,
          createNew: v4.DatabaseAtV4.new,
          openTestedDatabase: AppDatabase.forTesting,
          createItems: (batch, db) {
            batch.insert(
              db.notes,
              v1.NotesCompanion.insert(
                id: 'note-1',
                title: const Value('Psalm 23'),
                contentMarkdown: const Value('The Lord is my shepherd'),
                createdAt: createdAt,
                updatedAt: createdAt,
              ),
            );
            batch.insert(
              db.bibleAnnotations,
              v1.BibleAnnotationsCompanion.insert(
                id: 'highlight:JHN.3.16',
                verseRef: 'JHN.3.16',
                kind: 'highlight',
                color: const Value('yellow'),
                updatedAt: createdAt,
              ),
            );
          },
          validateItems: (db) async {
            final note = await db.select(db.notes).getSingle();
            expect(note.id, 'note-1');
            expect(note.title, 'Psalm 23');
            expect(note.contentMarkdown, 'The Lord is my shepherd');
            // Same instant, not the same object: drift persists a DateTime as
            // epoch seconds and reads it back in local time, so a UTC fixture
            // comes out as its local-zone equivalent.
            expect(note.createdAt.isAtSameMomentAs(createdAt), isTrue);

            final annotation = await db.select(db.bibleAnnotations).getSingle();
            expect(annotation.verseRef, 'JHN.3.16');
            expect(annotation.color, 'yellow');

            // notes_fts is created with customStatement, so drift's schema
            // model cannot see it and migrateAndValidate says nothing about it.
            // Without this assertion a broken _backfillNotesSearchIndex would
            // ship silently: upgraded users keep their notes but can never find
            // them in search.
            final hits = await db
                .customSelect(
                  "SELECT note_id FROM notes_fts WHERE notes_fts "
                  "MATCH 'shepherd'",
                )
                .get();
            expect(
              hits.map((r) => r.read<String>('note_id')),
              ['note-1'],
              reason: 'the upgrade must backfill pre-existing notes into FTS',
            );
          },
        );
      });
    });
  });

  group('Given a v3 database -- what almost every real install is on today', () {
    group('When it migrates to v4 (the daily habit loop tables)', () {
      test('Then existing notes survive AND the new tables are usable',
          () async {
        // The upgrade that ships next, so it gets the closest look. Two halves,
        // and passing only one of them is still a broken release: the notes
        // people already wrote must come through untouched, and the tables the
        // new feature writes to must actually exist afterwards.
        final createdAt = DateTime.utc(2026, 1, 15, 9, 30);

        await verifier.testWithDataIntegrity(
          oldVersion: 3,
          newVersion: 4,
          createOld: v3.DatabaseAtV3.new,
          createNew: v4.DatabaseAtV4.new,
          openTestedDatabase: AppDatabase.forTesting,
          createItems: (batch, db) {
            batch.insert(
              db.notes,
              v3.NotesCompanion.insert(
                id: 'sermon-note',
                title: const Value('Sunday'),
                contentMarkdown: const Value('Grace upon grace'),
                createdAt: createdAt,
                updatedAt: createdAt,
              ),
            );
            batch.insert(
              db.bibleAnnotations,
              v3.BibleAnnotationsCompanion.insert(
                id: 'highlight:ROM.8.28',
                verseRef: 'ROM.8.28',
                kind: 'highlight',
                color: const Value('green'),
                updatedAt: createdAt,
              ),
            );
          },
          validateItems: (db) async {
            // Half one: nothing was lost on the way up.
            final note = await db.select(db.notes).getSingle();
            expect(note.title, 'Sunday');
            expect(note.contentMarkdown, 'Grace upon grace');

            final annotation = await db.select(db.bibleAnnotations).getSingle();
            expect(annotation.verseRef, 'ROM.8.28');
            expect(annotation.color, 'green');

            // Half two: the new tables exist and take a write. A migration that
            // creates a table with the wrong shape still passes a schema diff
            // against a snapshot generated from that same wrong shape -- only
            // actually writing a row proves it is usable.
            await db.into(db.readingDays).insert(
                  v4.ReadingDaysCompanion.insert(
                    dateKey: '2026-01-15',
                    source: 'plan',
                    completedAt: createdAt,
                  ),
                );
            await db.into(db.planSubscriptions).insert(
                  v4.PlanSubscriptionsCompanion.insert(
                    planId: 'bible-in-a-year',
                    startDateKey: '2026-01-15',
                  ),
                );
            await db.into(db.planDayProgress).insert(
                  v4.PlanDayProgressCompanion.insert(
                    id: 'bible-in-a-year:1',
                    planId: 'bible-in-a-year',
                    dayIndex: 1,
                    completedAt: createdAt,
                  ),
                );

            expect(await db.select(db.readingDays).get(), hasLength(1));
            expect(await db.select(db.planSubscriptions).get(), hasLength(1));
            expect(await db.select(db.planDayProgress).get(), hasLength(1));
          },
        );
      });
    });
  });

  group('Given the schema snapshots guard future migrations', () {
    // The trap this closes: bump schemaVersion (or add a table) without dumping
    // a new snapshot, and every test above silently keeps testing the old
    // schema. This fails instead. Fix by running:
    //   dart run drift_dev schema dump lib/core/storage/database/app_database.dart drift_schemas/
    //   dart run drift_dev schema generate --data-classes --companions drift_schemas/ test/drift_schemas/
    test('Then a snapshot exists for the current schemaVersion', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final current = db.schemaVersion;
      await db.close();

      expect(
        File('drift_schemas/drift_schema_v$current.json').existsSync(),
        isTrue,
        reason: 'schemaVersion is $current but drift_schemas/ has no snapshot '
            'for it — run `drift_dev schema dump` (see comment above)',
      );
      expect(
        GeneratedHelper.versions,
        contains(current),
        reason: 'snapshot exists but the test helpers are stale — run '
            '`drift_dev schema generate` (see comment above)',
      );
    });
  });
}
