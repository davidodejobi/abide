import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';

import '../../../drift_schemas/schema.dart';
import '../../../drift_schemas/schema_v1.dart' as v1;
import '../../../drift_schemas/schema_v3.dart' as v3;

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

  group('Given a database created at an older schema version', () {
    // Every version users could still be sitting on. Testing only the newest
    // hop (2 -> 3) would miss the person who last opened the app months ago.
    for (final from in [1, 2]) {
      group('When the current app opens it', () {
        test('Then v$from migrates to v3 and the schema matches', () async {
          final connection = await verifier.startAt(from);
          final db = AppDatabase.forTesting(connection);

          // Runs the real onUpgrade, then compares the resulting schema against
          // the v3 reference. A migration branch that forgets a createTable
          // fails here rather than on a user's phone.
          await verifier.migrateAndValidate(db, 3);

          await db.close();
        });
      });
    }
  });

  group('Given a v1 database holding real user data', () {
    group('When it migrates to v3', () {
      test('Then notes and highlights survive, and search is backfilled',
          () async {
        // Fixed timestamps: the assertions below compare them exactly.
        final createdAt = DateTime.utc(2026, 1, 15, 9, 30);

        await verifier.testWithDataIntegrity(
          oldVersion: 1,
          newVersion: 3,
          createOld: v1.DatabaseAtV1.new,
          createNew: v3.DatabaseAtV3.new,
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
