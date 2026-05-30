import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/notes_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/database_provider.dart';
import 'package:openbaptisthymnal/features/tablet/data/repositories/tablets_repository.dart';
import 'package:openbaptisthymnal/features/tablet/data/sources/local/tablets_local_source.dart';

final tabletsLocalSourceProvider = Provider<TabletsLocalSource>((ref) {
  return TabletsLocalSource(
    ref.watch(notesDaoProvider),
    ref.watch(noteLinksDaoProvider),
    ref.watch(foldersDaoProvider),
    ref.watch(tagsDaoProvider),
  );
});

final tabletsRepositoryProvider = Provider<TabletsRepository>((ref) {
  return TabletsRepository(ref.watch(tabletsLocalSourceProvider));
});

/// Live list of the user's notes, newest edit first.
final tabletsListProvider = StreamProvider<List<Note>>((ref) {
  return ref.watch(tabletsRepositoryProvider).watchNotes();
});

/// Live single note for the editor; null while loading or if it doesn't exist.
final tabletByIdProvider = StreamProvider.family<Note?, String>((ref, id) {
  return ref.watch(tabletsRepositoryProvider).watchNote(id);
});

/// Outgoing links parsed from a note's markdown.
final outgoingLinksProvider =
    StreamProvider.family<List<NoteLink>, String>((ref, noteId) {
  return ref.watch(tabletsRepositoryProvider).watchOutgoingLinks(noteId);
});

/// Active notes that link to the given title (case-insensitive backlinks).
final backlinksProvider =
    StreamProvider.family<List<Note>, String>((ref, title) {
  return ref.watch(tabletsRepositoryProvider).watchBacklinks(title);
});

/// All folders, sorted by name, for the filter chips and the move picker.
final foldersProvider = StreamProvider<List<Folder>>((ref) {
  return ref.watch(tabletsRepositoryProvider).watchFolders();
});

/// The folder currently selected on the tablets tab; null means "All".
final activeFolderProvider = StateProvider<String?>((ref) => null);

/// Live list of tablets in a single folder, newest edit first.
final tabletsInFolderProvider =
    StreamProvider.family<List<Note>, String>((ref, folderId) {
  return ref.watch(tabletsRepositoryProvider).watchNotesInFolder(folderId);
});

/// All tags, sorted by name, for the tag picker and filter.
final tagsProvider = StreamProvider<List<Tag>>((ref) {
  return ref.watch(tabletsRepositoryProvider).watchTags();
});

/// Tags currently attached to a single tablet.
final tagsForNoteProvider =
    StreamProvider.family<List<Tag>, String>((ref, noteId) {
  return ref.watch(tabletsRepositoryProvider).watchTagsForNote(noteId);
});

/// Live list of tablets carrying a single tag, newest edit first.
final notesWithTagProvider =
    StreamProvider.family<List<Note>, String>((ref, tagId) {
  return ref.watch(tabletsRepositoryProvider).watchNotesWithTag(tagId);
});

/// Debounced full-text search over tablets, keyed by the raw query string.
/// Auto-disposes so superseded queries are cancelled: when the query changes,
/// the previous keystroke's provider is disposed and its pending debounce bails
/// out before hitting the database. Blank queries short-circuit to no results.
final tabletSearchProvider =
    FutureProvider.autoDispose.family<List<NoteSearchHit>, String>(
  (ref, query) async {
    if (query.trim().isEmpty) return const [];

    var cancelled = false;
    ref.onDispose(() => cancelled = true);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (cancelled) return const [];

    return ref.watch(tabletsRepositoryProvider).searchNotes(query);
  },
);
