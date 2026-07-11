import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/features/tablet/providers/tablets_providers.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/folder_picker_sheet.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/tag_picker_sheet.dart';

enum _ManageAction { rename, delete }

/// Bottom sheet that consolidates folder and tag filtering for the tablets tab.
/// Folder and tag filters are mutually exclusive: picking one clears the other.
/// Also the home for folder/tag management (create, rename, delete), so removing
/// the on-screen chip rows loses no functionality.
class TabletFilterSheet extends ConsumerWidget {
  const TabletFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final folders = ref.watch(foldersProvider).valueOrNull ?? const <Folder>[];
    final tags = ref.watch(tagsProvider).valueOrNull ?? const <Tag>[];
    final activeFolder = ref.watch(activeFolderProvider);
    final activeTag = ref.watch(activeTagProvider);

    void selectFolder(String? id) {
      ref.read(activeTagProvider.notifier).state = null;
      ref.read(activeFolderProvider.notifier).state = id;
      Navigator.of(context).pop();
    }

    void selectTag(String id) {
      ref.read(activeFolderProvider.notifier).state = null;
      ref.read(activeTagProvider.notifier).state =
          activeTag == id ? null : id;
      Navigator.of(context).pop();
    }

    Future<void> createFolder() async {
      final name = await promptFolderName(context);
      if (name == null || name.isEmpty) return;
      final id = await ref.read(tabletsRepositoryProvider).createFolder(name);
      ref.read(activeTagProvider.notifier).state = null;
      ref.read(activeFolderProvider.notifier).state = id;
      if (context.mounted) Navigator.of(context).pop();
    }

    Future<void> manageFolder(Folder folder) async {
      final action = await _showManageSheet(
        context,
        deleteLabel: 'Delete folder',
        deleteSubtitle: 'Tablets are kept and unfiled',
      );
      final repo = ref.read(tabletsRepositoryProvider);
      if (action == _ManageAction.rename) {
        if (!context.mounted) return;
        final name = await promptFolderName(context, initial: folder.name);
        if (name != null && name.isNotEmpty) {
          await repo.renameFolder(folder.id, name);
        }
      } else if (action == _ManageAction.delete) {
        await repo.deleteFolder(folder.id);
        if (activeFolder == folder.id) {
          ref.read(activeFolderProvider.notifier).state = null;
        }
      }
    }

    Future<void> manageTag(Tag tag) async {
      final action = await _showManageSheet(
        context,
        deleteLabel: 'Delete tag',
        deleteSubtitle: 'Tablets are kept and untagged',
      );
      final repo = ref.read(tabletsRepositoryProvider);
      if (action == _ManageAction.rename) {
        if (!context.mounted) return;
        final name = await promptTagName(context, initial: tag.name);
        if (name != null && name.isNotEmpty) {
          await repo.renameTag(tag.id, name);
        }
      } else if (action == _ManageAction.delete) {
        await repo.deleteTag(tag.id);
        if (activeTag == tag.id) {
          ref.read(activeTagProvider.notifier).state = null;
        }
      }
    }

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          _SectionHeader(label: 'Folders', theme: theme),
          _FilterOption(
            label: 'All tablets',
            icon: PhosphorIcons.tray(),
            selected: activeFolder == null && activeTag == null,
            onTap: () => selectFolder(null),
          ),
          for (final folder in folders)
            _FilterOption(
              label: folder.name,
              icon: PhosphorIcons.folder(),
              selected: activeFolder == folder.id,
              onTap: () => selectFolder(folder.id),
              onManage: () => manageFolder(folder),
            ),
          ListTile(
            leading: Icon(PhosphorIcons.folderPlus()),
            title: const Text('New folder'),
            onTap: createFolder,
          ),
          if (tags.isNotEmpty) ...[
            const Divider(height: 8),
            _SectionHeader(label: 'Tags', theme: theme),
            for (final tag in tags)
              _FilterOption(
                label: '#${tag.name}',
                icon: PhosphorIcons.tag(),
                selected: activeTag == tag.id,
                onTap: () => selectTag(tag.id),
                onManage: () => manageTag(tag),
              ),
          ],
        ],
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  const _FilterOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.onManage,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onManage;

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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected) Icon(PhosphorIcons.check(), color: scheme.primary),
          if (onManage != null)
            IconButton(
              icon: Icon(PhosphorIcons.dotsThree()),
              tooltip: 'Manage',
              onPressed: onManage,
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}

Future<_ManageAction?> _showManageSheet(
  BuildContext context, {
  required String deleteLabel,
  required String deleteSubtitle,
}) {
  return showModalBottomSheet<_ManageAction>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(PhosphorIcons.pencilSimple()),
            title: const Text('Rename'),
            onTap: () => Navigator.of(context).pop(_ManageAction.rename),
          ),
          ListTile(
            leading: Icon(PhosphorIcons.trash()),
            title: Text(deleteLabel),
            subtitle: Text(deleteSubtitle),
            onTap: () => Navigator.of(context).pop(_ManageAction.delete),
          ),
        ],
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.theme});

  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
