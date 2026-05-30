import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'tags_dao.g.dart';

@DriftAccessor(tables: [Tags, NoteTags, Notes])
class TagsDao extends DatabaseAccessor<AppDatabase> with _$TagsDaoMixin {
  TagsDao(super.db);

  /// All tags, sorted by name (case-insensitive) for a stable picker order.
  Stream<List<Tag>> watchTags() {
    return (select(tags)
          ..orderBy([(t) => OrderingTerm(expression: t.name.lower())]))
        .watch();
  }

  Future<void> upsertTag(TagsCompanion tag) =>
      into(tags).insertOnConflictUpdate(tag);

  /// Tags attached to [noteId], alphabetical, for the note's tag row.
  Stream<List<Tag>> watchTagsForNote(String noteId) {
    final query = select(tags).join([
      innerJoin(noteTags, noteTags.tagId.equalsExp(tags.id)),
    ])
      ..where(noteTags.noteId.equals(noteId))
      ..orderBy([OrderingTerm(expression: tags.name.lower())]);
    return query.watch().map((rows) => rows.map((r) => r.readTable(tags)).toList());
  }

  /// Idempotent: attaching a tag already on the note is a no-op (composite PK).
  Future<void> addTagToNote(String noteId, String tagId) =>
      into(noteTags).insertOnConflictUpdate(
        NoteTagsCompanion.insert(noteId: noteId, tagId: tagId),
      );

  Future<void> removeTagFromNote(String noteId, String tagId) {
    return (delete(noteTags)
          ..where((t) => t.noteId.equals(noteId) & t.tagId.equals(tagId)))
        .go();
  }

  /// Live list of non-deleted tablets carrying [tagId], newest edit first.
  Stream<List<Note>> watchActiveNotesWithTag(String tagId) {
    final query = select(notes).join([
      innerJoin(noteTags, noteTags.noteId.equalsExp(notes.id)),
    ])
      ..where(noteTags.tagId.equals(tagId) & notes.isDeleted.equals(false))
      ..orderBy([OrderingTerm.desc(notes.updatedAt)]);
    return query
        .watch()
        .map((rows) => rows.map((r) => r.readTable(notes)).toList());
  }

  /// Deletes a tag and detaches it from every tablet it was on, so removing a
  /// tag never loses a tablet. Done in one transaction; clearing the junction
  /// rows also satisfies the `NoteTags.tagId` foreign key.
  Future<void> deleteTag(String id) {
    return transaction(() async {
      await (delete(noteTags)..where((t) => t.tagId.equals(id))).go();
      await (delete(tags)..where((t) => t.id.equals(id))).go();
    });
  }
}
