import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/database_provider.dart';
import 'package:openbaptisthymnal/features/notes/data/repositories/notes_repository.dart';
import 'package:openbaptisthymnal/features/notes/data/sources/local/notes_local_source.dart';

final notesLocalSourceProvider = Provider<NotesLocalSource>((ref) {
  return NotesLocalSource(ref.watch(notesDaoProvider));
});

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository(ref.watch(notesLocalSourceProvider));
});

/// Live list of the user's notes, newest edit first.
final notesListProvider = StreamProvider<List<Note>>((ref) {
  return ref.watch(notesRepositoryProvider).watchNotes();
});

/// Live single note for the editor; null while loading or if it doesn't exist.
final noteByIdProvider = StreamProvider.family<Note?, String>((ref, id) {
  return ref.watch(notesRepositoryProvider).watchNote(id);
});
