import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'note_links_dao.g.dart';

@DriftAccessor(tables: [NoteLinks, Notes])
class NoteLinksDao extends DatabaseAccessor<AppDatabase>
    with _$NoteLinksDaoMixin {
  NoteLinksDao(super.db);

  /// Outgoing links a note points at.
  Stream<List<NoteLink>> watchOutgoing(String sourceNoteId) =>
      (select(noteLinks)..where((t) => t.sourceNoteId.equals(sourceNoteId)))
          .watch();

  /// Backlinks: active notes whose markdown links to this note by title
  /// (case-insensitive). Returns the linking notes, not the link rows.
  Stream<List<Note>> watchBacklinks(String title) {
    final query = select(notes).join([
      innerJoin(noteLinks, noteLinks.sourceNoteId.equalsExp(notes.id)),
    ])
      ..where(noteLinks.targetType.equals('note') &
          noteLinks.targetKey.lower().equals(title.toLowerCase()) &
          notes.isDeleted.equals(false))
      ..orderBy([OrderingTerm.desc(notes.updatedAt)]);

    return query.watch().map(
          (rows) => rows.map((r) => r.readTable(notes)).toList(),
        );
  }

  /// Replaces the full outgoing-link set for a note in a single transaction.
  Future<void> replaceLinksForNote(
    String sourceNoteId,
    List<NoteLinksCompanion> links,
  ) {
    return transaction(() async {
      await (delete(noteLinks)
            ..where((t) => t.sourceNoteId.equals(sourceNoteId)))
          .go();
      if (links.isNotEmpty) {
        await batch((b) => b.insertAll(noteLinks, links));
      }
    });
  }
}
