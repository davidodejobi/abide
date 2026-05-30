import 'package:drift/drift.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/note_links_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/notes_dao.dart';
import 'package:openbaptisthymnal/features/notes/domain/parse_links.dart';
import 'package:uuid/uuid.dart';

/// Local (offline) persistence for notes, backed by Drift. A future remote
/// source can sit beside this behind [NotesRepository].
class NotesLocalSource {
  NotesLocalSource(this._dao, this._linksDao, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  final NotesDao _dao;
  final NoteLinksDao _linksDao;
  final Uuid _uuid;

  Stream<List<Note>> watchNotes() => _dao.watchActiveNotes();

  Stream<Note?> watchNote(String id) => _dao.watchNote(id);

  Future<Note?> getNote(String id) => _dao.getNote(id);

  Stream<List<NoteLink>> watchOutgoingLinks(String noteId) =>
      _linksDao.watchOutgoing(noteId);

  Stream<List<Note>> watchBacklinks(String title) =>
      _linksDao.watchBacklinks(title);

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
    await _syncLinks(id, contentMarkdown);
    return id;
  }

  Future<void> updateNote({
    required String id,
    required String title,
    required String contentMarkdown,
    required DateTime createdAt,
  }) async {
    await _dao.upsertNote(
      NotesCompanion(
        id: Value(id),
        title: Value(title),
        contentMarkdown: Value(contentMarkdown),
        createdAt: Value(createdAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await _syncLinks(id, contentMarkdown);
  }

  Future<void> deleteNote(String id) => _dao.softDelete(id);

  /// Re-derives the outgoing link set from [contentMarkdown] and persists it.
  Future<void> _syncLinks(String noteId, String contentMarkdown) {
    final links = parseLinks(contentMarkdown).map((link) {
      return NoteLinksCompanion.insert(
        id: _uuid.v4(),
        sourceNoteId: noteId,
        targetType: link.type.name,
        targetKey: link.targetKey,
        rawToken: link.rawToken,
      );
    }).toList();
    return _linksDao.replaceLinksForNote(noteId, links);
  }
}
