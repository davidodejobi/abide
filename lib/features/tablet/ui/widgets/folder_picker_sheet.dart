import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/features/tablet/providers/tablets_providers.dart';

/// Bottom sheet to move a tablet into a folder (or unfile it). Lists existing
/// folders with the current one checked, plus an inline "New folder" action.
class FolderPickerSheet extends ConsumerWidget {
  const FolderPickerSheet({required this.noteId, super.key});

  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final foldersAsync = ref.watch(foldersProvider);
    final currentFolderId =
        ref.watch(tabletByIdProvider(noteId)).valueOrNull?.folderId;

    Future<void> move(String? folderId) async {
      await ref.read(tabletsRepositoryProvider).moveNoteToFolder(
            noteId,
            folderId,
          );
      if (context.mounted) Navigator.of(context).pop();
    }

    Future<void> createAndMove() async {
      final name = await promptFolderName(context);
      if (name == null || name.isEmpty) return;
      final id = await ref.read(tabletsRepositoryProvider).createFolder(name);
      await move(id);
    }

    return SafeArea(
      child: foldersAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Could not load folders: $err'),
        ),
        data: (folders) => ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                'Move to folder',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            _FolderOption(
              label: 'Unfiled',
              icon: Icons.inbox_outlined,
              selected: currentFolderId == null,
              onTap: () => move(null),
            ),
            for (final folder in folders)
              _FolderOption(
                label: folder.name,
                icon: Icons.folder_outlined,
                selected: folder.id == currentFolderId,
                onTap: () => move(folder.id),
              ),
            const Divider(height: 8),
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: const Text('New folder'),
              onTap: createAndMove,
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderOption extends StatelessWidget {
  const _FolderOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: selected ? scheme.primary : null),
      title: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? scheme.primary : null,
        ),
      ),
      trailing: selected ? Icon(Icons.check, color: scheme.primary) : null,
      onTap: onTap,
    );
  }
}

/// Prompts for a folder name. Returns the trimmed name, or null if cancelled
/// or empty. Pre-fills [initial] when renaming.
Future<String?> promptFolderName(BuildContext context, {String? initial}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(initial == null ? 'New folder' : 'Rename folder'),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Folder name'),
        onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(controller.text.trim()),
          child: Text(initial == null ? 'Create' : 'Save'),
        ),
      ],
    ),
  );
}
