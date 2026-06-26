import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'note_links_dao.g.dart';

/// One tablet that links into a Bible passage: the raw verse target plus the
/// bits of the source note needed to render a backlink row and open it.
class BibleBacklink {
  const BibleBacklink({
    required this.targetKey,
    required this.noteId,
    required this.noteTitle,
  });

  /// USFM verse target as stored, e.g. `JHN.3.16` or `JHN.3.16-21`.
  final String targetKey;
  final String noteId;
  final String noteTitle;
}

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

  /// Active tablets linking anywhere into [bookCode]. Coarse book-prefix filter
  /// in SQL (keeps the query boring across Drift versions); the caller expands
  /// ranges and maps them to verses for the wanted chapter in Dart. The `.`
  /// after the code keeps `JHN` from matching `1JN`/`2JN`/`3JN`.
  Stream<List<BibleBacklink>> watchBibleBacklinksForBook(String bookCode) {
    final query = select(noteLinks).join([
      innerJoin(notes, notes.id.equalsExp(noteLinks.sourceNoteId)),
    ])
      ..where(noteLinks.targetType.equals('bible') &
          notes.isDeleted.equals(false) &
          noteLinks.targetKey.like('$bookCode.%'))
      ..orderBy([OrderingTerm.desc(notes.updatedAt)]);

    return query.watch().map(
          (rows) => rows.map((r) {
            final link = r.readTable(noteLinks);
            final note = r.readTable(notes);
            return BibleBacklink(
              targetKey: link.targetKey,
              noteId: note.id,
              noteTitle: note.title,
            );
          }).toList(),
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
