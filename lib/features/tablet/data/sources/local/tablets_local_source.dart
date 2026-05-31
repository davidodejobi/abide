import 'package:drift/drift.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/folders_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/note_links_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/notes_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/tags_dao.dart';
import 'package:openbaptisthymnal/features/tablet/domain/parse_links.dart';
import 'package:uuid/uuid.dart';

/// Local (offline) persistence for notes, backed by Drift. A future remote
/// source can sit beside this behind [TabletsRepository].
class TabletsLocalSource {
  TabletsLocalSource(
    this._dao,
    this._linksDao,
    this._foldersDao,
    this._tagsDao, {
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  final NotesDao _dao;
  final NoteLinksDao _linksDao;
  final FoldersDao _foldersDao;
  final TagsDao _tagsDao;
  final Uuid _uuid;

  Stream<List<Note>> watchNotes() => _dao.watchActiveNotes();

  Stream<Note?> watchNote(String id) => _dao.watchNote(id);

  Future<Note?> getNote(String id) => _dao.getNote(id);

  Stream<List<NoteLink>> watchOutgoingLinks(String noteId) =>
      _linksDao.watchOutgoing(noteId);

  Stream<List<Note>> watchBacklinks(String title) =>
      _linksDao.watchBacklinks(title);

  Future<List<NoteSearchHit>> searchNotes(String query) =>
      _dao.searchNotes(query);

  Stream<List<Folder>> watchFolders() => _foldersDao.watchFolders();

  Stream<List<Note>> watchNotesInFolder(String folderId) =>
      _dao.watchActiveNotesInFolder(folderId);

  /// Creates a folder and returns its generated id.
  Future<String> createFolder(String name) async {
    final id = _uuid.v4();
    await _foldersDao.upsertFolder(FoldersCompanion.insert(id: id, name: name));
    return id;
  }

  Future<void> renameFolder(String id, String name) => _foldersDao
      .upsertFolder(FoldersCompanion(id: Value(id), name: Value(name)));

  Future<void> deleteFolder(String id) => _foldersDao.deleteFolder(id);

  Future<void> moveNoteToFolder(String noteId, String? folderId) =>
      _dao.setFolder(noteId, folderId);

  Stream<List<Tag>> watchTags() => _tagsDao.watchTags();

  Stream<List<Tag>> watchTagsForNote(String noteId) =>
      _tagsDao.watchTagsForNote(noteId);

  Stream<List<Note>> watchNotesWithTag(String tagId) =>
      _tagsDao.watchActiveNotesWithTag(tagId);

  /// Creates a tag and returns its generated id.
  Future<String> createTag(String name) async {
    final id = _uuid.v4();
    await _tagsDao.upsertTag(TagsCompanion.insert(id: id, name: name));
    return id;
  }

  Future<void> renameTag(String id, String name) =>
      _tagsDao.upsertTag(TagsCompanion(id: Value(id), name: Value(name)));

  Future<void> deleteTag(String id) => _tagsDao.deleteTag(id);

  Future<void> addTagToNote(String noteId, String tagId) =>
      _tagsDao.addTagToNote(noteId, tagId);

  Future<void> removeTagFromNote(String noteId, String tagId) =>
      _tagsDao.removeTagFromNote(noteId, tagId);

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
