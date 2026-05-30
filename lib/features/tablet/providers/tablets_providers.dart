import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/database_provider.dart';
import 'package:openbaptisthymnal/features/tablet/data/repositories/tablets_repository.dart';
import 'package:openbaptisthymnal/features/tablet/data/sources/local/tablets_local_source.dart';

final tabletsLocalSourceProvider = Provider<TabletsLocalSource>((ref) {
  return TabletsLocalSource(
    ref.watch(notesDaoProvider),
    ref.watch(noteLinksDaoProvider),
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
