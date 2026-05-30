import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'notes_dao.g.dart';

@DriftAccessor(tables: [Notes])
class NotesDao extends DatabaseAccessor<AppDatabase> with _$NotesDaoMixin {
  NotesDao(super.db);

  /// Live list of non-deleted notes, most recently edited first.
  Stream<List<Note>> watchActiveNotes() {
    return (select(notes)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Future<Note?> getNote(String id) =>
      (select(notes)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<Note?> watchNote(String id) =>
      (select(notes)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<void> upsertNote(NotesCompanion note) =>
      into(notes).insertOnConflictUpdate(note);

  Future<void> softDelete(String id) =>
      (update(notes)..where((t) => t.id.equals(id))).write(
        NotesCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );
}
