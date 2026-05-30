import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/features/notes/data/sources/local/notes_local_source.dart';

/// Offline-first entry point for note data. For now it delegates to the local
/// Drift source; a remote source can be layered in later without UI changes.
class NotesRepository {
  NotesRepository(this._local);

  final NotesLocalSource _local;

  Stream<List<Note>> watchNotes() => _local.watchNotes();

  Stream<Note?> watchNote(String id) => _local.watchNote(id);

  Future<Note?> getNote(String id) => _local.getNote(id);

  Future<String> createNote({String title = '', String contentMarkdown = ''}) =>
      _local.createNote(title: title, contentMarkdown: contentMarkdown);

  Future<void> updateNote({
    required String id,
    required String title,
    required String contentMarkdown,
    required DateTime createdAt,
  }) =>
      _local.updateNote(
        id: id,
        title: title,
        contentMarkdown: contentMarkdown,
        createdAt: createdAt,
      );

  Future<void> deleteNote(String id) => _local.deleteNote(id);
}
