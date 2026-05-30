import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'dart:io';

import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/features/notes/domain/note_preview.dart';
import 'package:openbaptisthymnal/features/notes/providers/notes_providers.dart';

/// Notes tab — the app's default landing screen. Lists the user's notes and
/// opens the editor for create/edit.
@RoutePage()
class NotesTabScreen extends HookConsumerWidget {
  const NotesTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useAutomaticKeepAlive();

    final notesAsync = ref.watch(notesListProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 24),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Tablets',
                  style: AppTextStyles.headlineLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'New tablet',
                onPressed: () => context.router.push(NoteEditorRoute()),
              ),
            ],
          ),
        ),
        Expanded(
          child: notesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) =>
                Center(child: Text('Could not load notes: $err')),
            data: (notes) {
              if (notes.isEmpty) return const _EmptyNotes();
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                itemCount: notes.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) => _NoteTile(note: notes[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NoteTile extends ConsumerWidget {
  const _NoteTile({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = note.title.trim().isEmpty ? 'Untitled' : note.title.trim();
    final preview = notePreviewText(note.contentMarkdown);
    final imagePath = notePreviewImage(note.contentMarkdown);

    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Theme.of(context).colorScheme.errorContainer,
        child: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
      onDismissed: (_) => ref.read(notesRepositoryProvider).deleteNote(note.id),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 6),
        leading: imagePath == null ? null : _NoteThumbnail(path: imagePath),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: preview.isEmpty
            ? (imagePath == null
                ? null
                : Text(
                    'Photo',
                    style: TextStyle(
                      fontFamily: 'EBGaramond',
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ))
            : Text(
                preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'EBGaramond', fontSize: 15),
              ),
        onTap: () => context.router.push(NoteEditorRoute(noteId: note.id)),
      ),
    );
  }
}

/// Square rounded thumbnail for the first image in a note. Falls back to a
/// neutral image-broken icon if the file is missing.
class _NoteThumbnail extends StatelessWidget {
  const _NoteThumbnail({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isNetwork = path.startsWith('http');
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: isNetwork
            ? Image.network(path, fit: BoxFit.cover)
            : Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: scheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 22,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
      ),
    );
  }
}

class _EmptyNotes extends StatelessWidget {
  const _EmptyNotes();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit_note, size: 64, color: color),
          const SizedBox(height: 12),
          Text(
            'No tablets yet',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + to write your first tablet',
            style:
                TextStyle(fontFamily: 'EBGaramond', fontSize: 15, color: color),
          ),
        ],
      ),
    );
  }
}
