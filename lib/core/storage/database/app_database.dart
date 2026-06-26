import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'daos/bible_annotations_dao.dart';
import 'daos/folders_dao.dart';
import 'daos/note_links_dao.dart';
import 'daos/notes_dao.dart';
import 'daos/tags_dao.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Notes,
    Folders,
    Tags,
    NoteTags,
    NoteLinks,
    Attachments,
    BibleAnnotations,
  ],
  daos: [NotesDao, NoteLinksDao, FoldersDao, TagsDao, BibleAnnotationsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// In-memory connection for tests.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createNotesSearchIndex();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await _createNotesSearchIndex();
            await _backfillNotesSearchIndex();
          }
          if (from < 3) {
            await _ensureBibleAnnotations(m);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Creates the FTS5 mirror of [Notes] (`title` + `content_markdown`) and the
  /// triggers that keep it in sync. Markdown stays the source of truth; this
  /// index is fully derived and safe to drop/rebuild. `note_id` is UNINDEXED so
  /// results can be joined back to [Notes] (which has a TEXT primary key).
  Future<void> _createNotesSearchIndex() async {
    await customStatement(
      'CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5('
      'note_id UNINDEXED, title, content)',
    );
    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS notes_fts_ai AFTER INSERT ON notes BEGIN '
      'INSERT INTO notes_fts(note_id, title, content) '
      'VALUES (new.id, new.title, new.content_markdown); END',
    );
    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS notes_fts_ad AFTER DELETE ON notes BEGIN '
      'DELETE FROM notes_fts WHERE note_id = old.id; END',
    );
    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS notes_fts_au AFTER UPDATE ON notes BEGIN '
      'DELETE FROM notes_fts WHERE note_id = old.id; '
      'INSERT INTO notes_fts(note_id, title, content) '
      'VALUES (new.id, new.title, new.content_markdown); END',
    );
  }

  /// Seeds the freshly created index from existing rows (upgrade path only).
  Future<void> _backfillNotesSearchIndex() async {
    await customStatement(
      'INSERT INTO notes_fts(note_id, title, content) '
      'SELECT id, title, content_markdown FROM notes',
    );
  }

  /// Creates `bible_annotations` on upgrade, but only if it isn't already there.
  /// The table was registered in the Dart schema before it had a migration, so
  /// some installs already have it (via an earlier `createAll`) while others
  /// don't. The existence check keeps this idempotent either way, and using the
  /// generated [createTable] guarantees the column types match the schema.
  Future<void> _ensureBibleAnnotations(Migrator m) async {
    final existing = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' "
      "AND name = 'bible_annotations'",
    ).get();
    if (existing.isEmpty) {
      await m.createTable(bibleAnnotations);
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'abide_notes.sqlite'));

    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    sqlite3.tempDirectory = (await getTemporaryDirectory()).path;

    return NativeDatabase.createInBackground(file);
  });
}
