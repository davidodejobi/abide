import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'dart:io';

import 'package:openbaptisthymnal/core/storage/database/daos/notes_dao.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/search_bar_widget.dart';
import 'package:openbaptisthymnal/features/tablet/domain/tablet_preview.dart';
import 'package:openbaptisthymnal/features/tablet/providers/tablets_providers.dart';

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
        Expanded(
          child: query.isEmpty
              ? const _TabletsList()
              : _SearchResults(query: query),
        ),
      ],
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
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
