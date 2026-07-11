import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'daos/bible_annotations_dao.dart';
import 'daos/folders_dao.dart';
import 'daos/note_links_dao.dart';
import 'daos/notes_dao.dart';
import 'daos/reading_plans_dao.dart';
import 'daos/tags_dao.dart';

/// App-wide Drift database. Lives for the whole app session (manual providers
/// do not auto-dispose) and is closed when the root scope tears down.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final notesDaoProvider = Provider<NotesDao>(
  (ref) => ref.watch(appDatabaseProvider).notesDao,
);

final noteLinksDaoProvider = Provider<NoteLinksDao>(
  (ref) => ref.watch(appDatabaseProvider).noteLinksDao,
);

final foldersDaoProvider = Provider<FoldersDao>(
  (ref) => ref.watch(appDatabaseProvider).foldersDao,
);

final tagsDaoProvider = Provider<TagsDao>(
  (ref) => ref.watch(appDatabaseProvider).tagsDao,
);

final bibleAnnotationsDaoProvider = Provider<BibleAnnotationsDao>(
  (ref) => ref.watch(appDatabaseProvider).bibleAnnotationsDao,
);

final readingPlansDaoProvider = Provider<ReadingPlansDao>(
  (ref) => ref.watch(appDatabaseProvider).readingPlansDao,
);
