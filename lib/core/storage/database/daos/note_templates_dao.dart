import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'note_templates_dao.g.dart';

@DriftAccessor(tables: [NoteTemplates])
class NoteTemplatesDao extends DatabaseAccessor<AppDatabase>
    with _$NoteTemplatesDaoMixin {
  NoteTemplatesDao(super.db);

  /// Live, non-deleted templates, oldest first so the list order is stable.
  Stream<List<NoteTemplate>> watchTemplates() {
    return (select(noteTemplates)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .watch();
  }

  Future<void> upsertTemplate(NoteTemplatesCompanion template) =>
      into(noteTemplates).insertOnConflictUpdate(template);

  /// Soft delete, so the undo snackbar can bring the template back.
  Future<void> setDeleted(String id, bool deleted) {
    return (update(noteTemplates)..where((t) => t.id.equals(id))).write(
      NoteTemplatesCompanion(
        isDeleted: Value(deleted),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
