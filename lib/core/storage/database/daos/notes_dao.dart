import 'package:drift/drift.dart';

import '../app_database.dart';
import '../fts_query.dart';
import '../tables.dart';

part 'notes_dao.g.dart';

/// A single full-text search result: the matched note plus a highlighted text
/// snippet (with `[` … `]` around the matched terms) for the results list.
class NoteSearchHit {
  const NoteSearchHit({required this.note, required this.snippet});

  final Note note;
  final String snippet;
}

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

  /// Live list of non-deleted tablets in a single folder, newest edit first.
  Stream<List<Note>> watchActiveNotesInFolder(String folderId) {
    return (select(notes)
          ..where((t) => t.isDeleted.equals(false) & t.folderId.equals(folderId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Future<void> upsertNote(NotesCompanion note) =>
      into(notes).insertOnConflictUpdate(note);

  /// Moves a tablet into [folderId] (or clears it when null). Organizational
  /// metadata only, so it deliberately does not bump `updatedAt`.
  Future<void> setFolder(String noteId, String? folderId) =>
      (update(notes)..where((t) => t.id.equals(noteId)))
          .write(NotesCompanion(folderId: Value(folderId)));

  /// Full-text search over active notes' title + body, best match first.
  /// Returns an empty list for blank input. The snippet is drawn from the body
  /// (with the title as fallback) and wraps matches in `[` … `]`.
  Future<List<NoteSearchHit>> searchNotes(String query) async {
    final match = buildFtsMatchQuery(query);
    if (match.isEmpty) return const [];

    final rows = await customSelect(
      'SELECT n.*, '
      "snippet(notes_fts, 2, '[', ']', '…', 12) AS snippet "
      'FROM notes_fts f '
      'JOIN notes n ON n.id = f.note_id '
      'WHERE notes_fts MATCH ? AND n.is_deleted = 0 '
      'ORDER BY bm25(notes_fts)',
      variables: [Variable<String>(match)],
      readsFrom: {notes},
    ).get();

    return rows
        .map((row) => NoteSearchHit(
              note: notes.map(row.data),
              snippet: row.read<String>('snippet'),
            ))
        .toList();
  }

  Future<void> softDelete(String id) =>
      (update(notes)..where((t) => t.id.equals(id))).write(
        NotesCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );
}
