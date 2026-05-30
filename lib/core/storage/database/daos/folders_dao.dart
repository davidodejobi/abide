import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'folders_dao.g.dart';

@DriftAccessor(tables: [Folders, Notes])
class FoldersDao extends DatabaseAccessor<AppDatabase> with _$FoldersDaoMixin {
  FoldersDao(super.db);

  /// All folders, sorted by name (case-insensitive) for a stable picker order.
  Stream<List<Folder>> watchFolders() {
    return (select(folders)
          ..orderBy([(t) => OrderingTerm(expression: t.name.lower())]))
        .watch();
  }

  Future<void> upsertFolder(FoldersCompanion folder) =>
      into(folders).insertOnConflictUpdate(folder);

  /// Deletes a folder and unassigns (rather than deletes) the tablets it held,
  /// so removing a folder never loses a tablet. Done in one transaction; the
  /// reparenting also satisfies the `Notes.folderId` foreign key.
  Future<void> deleteFolder(String id) {
    return transaction(() async {
      await (update(notes)..where((t) => t.folderId.equals(id)))
          .write(const NotesCompanion(folderId: Value(null)));
      await (delete(folders)..where((t) => t.id.equals(id))).go();
    });
  }
}
