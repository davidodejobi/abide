import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/features/tablet/providers/tablets_providers.dart';

/// Bottom sheet to manage a tablet's tags. Lists every tag with the ones on
/// this tablet checked; tapping toggles membership. An inline "New tag" action
/// creates a tag and attaches it in one step.
class TagPickerSheet extends ConsumerWidget {
  const TagPickerSheet({required this.noteId, super.key});

  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tagsAsync = ref.watch(tagsProvider);
    final noteTagIds = ref
            .watch(tagsForNoteProvider(noteId))
            .valueOrNull
            ?.map((t) => t.id)
            .toSet() ??
        const <String>{};

    Future<void> toggle(String tagId, bool isOn) async {
      final repo = ref.read(tabletsRepositoryProvider);
      if (isOn) {
        await repo.removeTagFromNote(noteId, tagId);
      } else {
        await repo.addTagToNote(noteId, tagId);
      }
    }

    Future<void> createAndAttach() async {
      final name = await promptTagName(context);
      if (name == null || name.isEmpty) return;
      final id = await ref.read(tabletsRepositoryProvider).createTag(name);
      await ref.read(tabletsRepositoryProvider).addTagToNote(noteId, id);
    }

    return SafeArea(
      child: tagsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Could not load tags: $err'),
        ),
        data: (tags) => ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                'Tags',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            if (tags.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text('No tags yet. Create one below.'),
              ),
            for (final tag in tags)
              CheckboxListTile(
                value: noteTagIds.contains(tag.id),
                title: Text(
                  tag.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (_) =>
                    toggle(tag.id, noteTagIds.contains(tag.id)),
              ),
            const Divider(height: 8),
            ListTile(
              leading: Icon(PhosphorIcons.plus()),
              title: const Text('New tag'),
              onTap: createAndAttach,
            ),
          ],
        ),
      ),
    );
  }
}

/// Prompts for a tag name. Returns the trimmed name, or null if cancelled or
/// empty. Pre-fills [initial] when renaming.
Future<String?> promptTagName(BuildContext context, {String? initial}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(initial == null ? 'New tag' : 'Rename tag'),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(hintText: 'Tag name'),
        onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          child: Text(initial == null ? 'Create' : 'Save'),
        ),
      ],
    ),
  );
}
