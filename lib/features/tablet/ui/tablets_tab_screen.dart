import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/notes_dao.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/search_bar_widget.dart';
import 'package:openbaptisthymnal/features/tablet/domain/tablet_preview.dart';
import 'package:openbaptisthymnal/features/tablet/providers/tablets_providers.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/folder_picker_sheet.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/tag_picker_sheet.dart';

/// Tablets tab — the app's default landing screen. Lists the user's tablets and
/// opens the editor for create/edit.
@RoutePage()
class TabletsTabScreen extends HookConsumerWidget {
  const TabletsTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useAutomaticKeepAlive();

    final searchController = useTextEditingController();
    final searchQuery = useState('');
    final query = searchQuery.value.trim();
    final activeFolder = ref.watch(activeFolderProvider);
    final activeTag = ref.watch(activeTagProvider);

    Widget body() {
      if (query.isNotEmpty) return _SearchResults(query: query);
      if (activeTag != null) return _TagTabletsList(tagId: activeTag);
      if (activeFolder != null) return _FolderTabletsList(folderId: activeFolder);
      return const _TabletsList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
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
                onPressed: () => context.router.push(TabletEditorRoute()),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SearchBarWidget(
            controller: searchController,
            hintText: 'Search tablets...',
            onChanged: (value) => searchQuery.value = value,
          ),
        ),
        if (query.isEmpty) ...[
          const _FolderChips(),
          const _TagChips(),
        ],
        Expanded(child: body()),
      ],
    );
  }
}

/// Horizontal folder filter: "All" plus a chip per folder and a trailing add
/// chip. Tapping selects the active filter; long-pressing a folder opens
/// rename/delete actions. Hidden while searching.
class _FolderChips extends ConsumerWidget {
  const _FolderChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersProvider);
    final active = ref.watch(activeFolderProvider);
    final tagActive = ref.watch(activeTagProvider) != null;
    final folders = foldersAsync.valueOrNull ?? const [];

    void selectFolder(String? id) {
      ref.read(activeTagProvider.notifier).state = null;
      ref.read(activeFolderProvider.notifier).state = id;
    }

    Future<void> createFolder() async {
      final name = await promptFolderName(context);
      if (name == null || name.isEmpty) return;
      final id = await ref.read(tabletsRepositoryProvider).createFolder(name);
      selectFolder(id);
    }

    Future<void> manageFolder(Folder folder) async {
      final action = await showModalBottomSheet<_FolderAction>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.drive_file_rename_outline),
                title: const Text('Rename'),
                onTap: () => Navigator.of(context).pop(_FolderAction.rename),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete folder'),
                subtitle: const Text('Tablets are kept and unfiled'),
                onTap: () => Navigator.of(context).pop(_FolderAction.delete),
              ),
            ],
          ),
        ),
      );
      final repo = ref.read(tabletsRepositoryProvider);
      if (action == _FolderAction.rename) {
        if (!context.mounted) return;
        final name = await promptFolderName(context, initial: folder.name);
        if (name != null && name.isNotEmpty) {
          await repo.renameFolder(folder.id, name);
        }
      } else if (action == _FolderAction.delete) {
        await repo.deleteFolder(folder.id);
        if (active == folder.id) {
          ref.read(activeFolderProvider.notifier).state = null;
        }
      }
    }

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _Chip(
            label: 'All',
            selected: active == null && !tagActive,
            onTap: () => selectFolder(null),
          ),
          for (final folder in folders) ...[
            const SizedBox(width: 10),
            _Chip(
              label: folder.name,
              selected: active == folder.id,
              onTap: () => selectFolder(folder.id),
              onLongPress: () => manageFolder(folder),
            ),
          ],
          const SizedBox(width: 10),
          _Chip(label: '+ New', selected: false, onTap: createFolder),
        ],
      ),
    );
  }
}

enum _FolderAction { rename, delete }

/// Horizontal tag filter: a chip per tag, shown only when tags exist. Tapping
/// selects (or, if already active, clears) the tag filter; long-pressing opens
/// rename/delete actions. Tags are created from the editor, not here. Hidden
/// while searching.
class _TagChips extends ConsumerWidget {
  const _TagChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagsProvider);
    final active = ref.watch(activeTagProvider);
    final tags = tagsAsync.valueOrNull ?? const [];
    if (tags.isEmpty) return const SizedBox.shrink();

    void selectTag(String? id) {
      ref.read(activeFolderProvider.notifier).state = null;
      ref.read(activeTagProvider.notifier).state = id;
    }

    Future<void> manageTag(Tag tag) async {
      final action = await showModalBottomSheet<_FolderAction>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.drive_file_rename_outline),
                title: const Text('Rename'),
                onTap: () => Navigator.of(context).pop(_FolderAction.rename),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete tag'),
                subtitle: const Text('Tablets are kept and untagged'),
                onTap: () => Navigator.of(context).pop(_FolderAction.delete),
              ),
            ],
          ),
        ),
      );
      final repo = ref.read(tabletsRepositoryProvider);
      if (action == _FolderAction.rename) {
        if (!context.mounted) return;
        final name = await promptTagName(context, initial: tag.name);
        if (name != null && name.isNotEmpty) {
          await repo.renameTag(tag.id, name);
        }
      } else if (action == _FolderAction.delete) {
        await repo.deleteTag(tag.id);
        if (active == tag.id) {
          ref.read(activeTagProvider.notifier).state = null;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            for (final tag in tags) ...[
              _Chip(
                label: '#${tag.name}',
                selected: active == tag.id,
                onTap: () => selectTag(active == tag.id ? null : tag.id),
                onLongPress: () => manageTag(tag),
              ),
              const SizedBox(width: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? scheme.primary : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Geist',
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// Live list of tablets in the active folder.
class _FolderTabletsList extends ConsumerWidget {
  const _FolderTabletsList({required this.folderId});

  final String folderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabletsAsync = ref.watch(tabletsInFolderProvider(folderId));
    return tabletsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Could not load tablets: $err')),
      data: (tablets) {
        if (tablets.isEmpty) return const _EmptyFolder();
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          itemCount: tablets.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) => _TabletTile(tablet: tablets[index]),
        );
      },
    );
  }
}

/// Live list of tablets carrying the active tag.
class _TagTabletsList extends ConsumerWidget {
  const _TagTabletsList({required this.tagId});

  final String tagId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabletsAsync = ref.watch(notesWithTagProvider(tagId));
    return tabletsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Could not load tablets: $err')),
      data: (tablets) {
        if (tablets.isEmpty) return const _EmptyTag();
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          itemCount: tablets.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) => _TabletTile(tablet: tablets[index]),
        );
      },
    );
  }
}

/// Live list of all tablets, shown when the search box is empty.
class _TabletsList extends ConsumerWidget {
  const _TabletsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabletsAsync = ref.watch(tabletsListProvider);
    return tabletsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Could not load tablets: $err')),
      data: (tablets) {
        if (tablets.isEmpty) return const _EmptyTablets();
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          itemCount: tablets.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) => _TabletTile(tablet: tablets[index]),
        );
      },
    );
  }
}

/// Debounced full-text search results for the current query.
class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(tabletSearchProvider(query));
    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Search failed: $err')),
      data: (hits) {
        if (hits.isEmpty) return _NoResults(query: query);
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          itemCount: hits.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) => _SearchResultTile(hit: hits[index]),
        );
      },
    );
  }
}

/// A single search hit: tablet title plus the highlighted snippet returned by
/// FTS5. Tapping opens the editor for that tablet.
class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.hit});

  final NoteSearchHit hit;

  @override
  Widget build(BuildContext context) {
    final note = hit.note;
    final title = note.title.trim().isEmpty ? 'Untitled' : note.title.trim();
    final snippet = hit.snippet.replaceAll(RegExp(r'\s+'), ' ').trim();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
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
      subtitle: snippet.isEmpty
          ? null
          : Text(
              snippet,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'EBGaramond', fontSize: 15),
            ),
      onTap: () => context.router.push(TabletEditorRoute(noteId: note.id)),
    );
  }
}

/// Empty state shown when a non-empty query matches no tablets.
class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: color),
          const SizedBox(height: 12),
          Text(
            'No tablets match "$query"',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabletTile extends ConsumerWidget {
  const _TabletTile({required this.tablet});

  final Note tablet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title =
        tablet.title.trim().isEmpty ? 'Untitled' : tablet.title.trim();
    final preview = notePreviewText(tablet.contentMarkdown);
    final imagePath = notePreviewImage(tablet.contentMarkdown);
    final hasAudio = imagePath == null && noteHasAudio(tablet.contentMarkdown);

    return Dismissible(
      key: ValueKey(tablet.id),
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
      onDismissed: (_) =>
          ref.read(tabletsRepositoryProvider).deleteNote(tablet.id),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 6),
        leading: imagePath != null
            ? _TabletThumbnail(path: imagePath)
            : hasAudio
                ? Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.mic_none,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                : null,
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
            ? ((imagePath == null && !hasAudio)
                ? null
                : Text(
                    hasAudio ? 'Voice tablet' : 'Photo',
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
        onTap: () => context.router.push(TabletEditorRoute(noteId: tablet.id)),
      ),
    );
  }
}

/// Square rounded thumbnail for the first image in a tablet. Falls back to a
/// neutral image-broken icon if the file is missing.
class _TabletThumbnail extends StatelessWidget {
  const _TabletThumbnail({required this.path});

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

/// Empty state shown when the selected folder has no tablets.
class _EmptyFolder extends StatelessWidget {
  const _EmptyFolder();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open_outlined, size: 64, color: color),
          const SizedBox(height: 12),
          Text(
            'This folder is empty',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Move tablets here from the editor',
            style:
                TextStyle(fontFamily: 'EBGaramond', fontSize: 15, color: color),
          ),
        ],
      ),
    );
  }
}

/// Empty state shown when the selected tag has no tablets.
class _EmptyTag extends StatelessWidget {
  const _EmptyTag();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.label_off_outlined, size: 64, color: color),
          const SizedBox(height: 12),
          Text(
            'Nothing tagged here',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add this tag to tablets from the editor',
            style:
                TextStyle(fontFamily: 'EBGaramond', fontSize: 15, color: color),
          ),
        ],
      ),
    );
  }
}

class _EmptyTablets extends StatelessWidget {
  const _EmptyTablets();

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
