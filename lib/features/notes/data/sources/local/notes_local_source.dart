import 'package:drift/drift.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/notes_dao.dart';
import 'package:uuid/uuid.dart';

/// Local (offline) persistence for notes, backed by Drift. A future remote
/// source can sit beside this behind [NotesRepository].
class NotesLocalSource {
  NotesLocalSource(this._dao, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final NotesDao _dao;
  final Uuid _uuid;

  Stream<List<Note>> watchNotes() => _dao.watchActiveNotes();

  Stream<Note?> watchNote(String id) => _dao.watchNote(id);

  Future<Note?> getNote(String id) => _dao.getNote(id);

  /// Inserts a new note and returns its generated id.
  Future<String> createNote({
    String title = '',
    String contentMarkdown = '',
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _dao.upsertNote(
      NotesCompanion.insert(
        id: id,
        title: Value(title),
        contentMarkdown: Value(contentMarkdown),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return id;
  }

  Future<void> updateNote({
    required String id,
    required String title,
    required String contentMarkdown,
    required DateTime createdAt,
  }) {
    return _dao.upsertNote(
      NotesCompanion(
        id: Value(id),
        title: Value(title),
        contentMarkdown: Value(contentMarkdown),
        createdAt: Value(createdAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteNote(String id) => _dao.softDelete(id);
}
