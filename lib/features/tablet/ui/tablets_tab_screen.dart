import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/notes_dao.dart';
import 'package:openbaptisthymnal/core/theme/app_colors.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/search_bar_widget.dart';
import 'package:openbaptisthymnal/features/tablet/domain/tablet_preview.dart';
import 'package:openbaptisthymnal/features/tablet/providers/tablets_providers.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/tablet_filter_sheet.dart';

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
    final hasFilter = activeFolder != null || activeTag != null;

    Widget body() {
      if (query.isNotEmpty) return _SearchResults(query: query);
      if (activeTag != null) return _TagTabletsList(tagId: activeTag);
      if (activeFolder != null) {
        return _FolderTabletsList(folderId: activeFolder);
      }
      return const _TabletsList();
    }

    // Lift the "new tablet" action off the top bar and into a thumb-reachable
    // FAB that floats just above the bottom navigation bar.
    final navClearance = MediaQuery.of(context).padding.bottom + 100;

    return Stack(
      children: [
        Column(
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
                  if (query.isEmpty)
                    IconButton(
                      icon: Icon(
                        hasFilter
                            ? Icons.filter_list
                            : Icons.filter_list_outlined,
                        color: hasFilter
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      tooltip: 'Filter tablets',
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        showDragHandle: true,
                        isScrollControlled: true,
                        useSafeArea: true,
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.9,
                        ),
                        builder: (_) => const TabletFilterSheet(),
                      ),
                    ),
                  const SizedBox(width: 4),
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
            if (query.isEmpty && hasFilter) const _ActiveFilterBar(),
            Expanded(child: body()),
          ],
        ),
        // Thumb-reachable primary action, floating clear of the bottom nav.
        Positioned(
          right: 20,
          bottom: navClearance,
          child: FloatingActionButton(
            heroTag: 'new_tablet_fab',
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.primaryDark,
            elevation: 4,
            tooltip: 'New tablet',
            onPressed: () => context.router.push(TabletEditorRoute()),
            child: const Icon(Icons.add_rounded, size: 28),
          ),
        ),
      ],
    );
  }
}

/// A dismissible strip naming the active folder/tag filter so the user can see
/// what's narrowing the list now that the chip rows are gone, and clear it.
class _ActiveFilterBar extends ConsumerWidget {
  const _ActiveFilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final activeFolder = ref.watch(activeFolderProvider);
    final activeTag = ref.watch(activeTagProvider);

    String? label;
    if (activeTag != null) {
      final tag = (ref.watch(tagsProvider).valueOrNull ?? const [])
          .where((t) => t.id == activeTag)
          .firstOrNull;
      if (tag != null) label = '#${tag.name}';
    } else if (activeFolder != null) {
      final folder = (ref.watch(foldersProvider).valueOrNull ?? const [])
          .where((f) => f.id == activeFolder)
          .firstOrNull;
      if (folder != null) label = folder.name;
    }
    if (label == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InputChip(
          label: Text(label),
          avatar: Icon(
            activeTag != null ? Icons.label_outline : Icons.folder_outlined,
            size: 18,
          ),
          backgroundColor: scheme.primaryContainer,
          labelStyle: TextStyle(
            color: scheme.onPrimaryContainer,
            fontFamily: 'Geist',
            fontWeight: FontWeight.w600,
          ),
          deleteIconColor: scheme.onPrimaryContainer,
          onDeleted: () {
            ref.read(activeFolderProvider.notifier).state = null;
            ref.read(activeTagProvider.notifier).state = null;
          },
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
                      borderRadius: BorderRadius.circular(12),
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
        subtitle: _TabletSubtitle(
          noteId: tablet.id,
          preview: preview,
          hasAudio: hasAudio,
          hasImage: imagePath != null,
        ),
        onTap: () => context.router.push(TabletEditorRoute(noteId: tablet.id)),
      ),
    );
  }
}

/// Tablet tile subtitle: preview text (or a media label) above a wrap of the
/// tablet's tags. Tags are watched per tile, so attaching/removing one in the
/// editor reflects here live.
class _TabletSubtitle extends ConsumerWidget {
  const _TabletSubtitle({
    required this.noteId,
    required this.preview,
    required this.hasAudio,
    required this.hasImage,
  });

  final String noteId;
  final String preview;
  final bool hasAudio;
  final bool hasImage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final tags = ref.watch(tagsForNoteProvider(noteId)).valueOrNull ?? const [];

    Widget? primary;
    if (preview.isNotEmpty) {
      primary = Text(
        preview,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodyMedium.copyWith(
          fontFamily: AppTextStyles.fontFamilyGeist,
          color: scheme.onSurfaceVariant,
        ),
      );
    } else if (hasAudio || hasImage) {
      primary = Text(
        hasAudio ? 'Voice tablet' : 'Photo',
        style: AppTextStyles.bodyMedium.copyWith(
          fontFamily: AppTextStyles.fontFamilyGeist,
          color: scheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (primary != null) primary,
        if (tags.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: primary != null ? 6 : 2),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final tag in tags)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '#${tag.name}',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
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
      borderRadius: BorderRadius.circular(12),
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
