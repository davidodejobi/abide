import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/notes_dao.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/widgets/lum_button.dart';
import 'package:openbaptisthymnal/core/widgets/lum_chip.dart';
import 'package:openbaptisthymnal/core/widgets/lum_group_card.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/search_bar_widget.dart';
import 'package:openbaptisthymnal/features/tablet/domain/note_date_label.dart';
import 'package:openbaptisthymnal/features/tablet/domain/tablet_preview.dart';
import 'package:openbaptisthymnal/features/tablet/providers/tablets_providers.dart';
import 'package:openbaptisthymnal/features/tablet/providers/templates_providers.dart';
import 'package:openbaptisthymnal/features/tablet/ui/notes_strings.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/new_note_sheet.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/tablet_filter_sheet.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// The Notes tab (Figma M4-01 list, M4-03 empty): title, search, filter and the
/// note cards. Opens the editor to create or edit. The class keeps its old
/// name so the generated route stays put.
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
    final all = ref.watch(tabletsListProvider);
    final total = all.valueOrNull?.length;
    final c = context.lum;

    // The count follows whatever list is on screen: search hits, the active
    // tag or folder, or every note.
    final int? shown = query.isNotEmpty
        ? ref.watch(tabletSearchProvider(query)).valueOrNull?.length
        : activeTag != null
            ? ref.watch(notesWithTagProvider(activeTag)).valueOrNull?.length
            : activeFolder != null
                ? ref
                    .watch(tabletsInFolderProvider(activeFolder))
                    .valueOrNull
                    ?.length
                : total;

    // A brand-new notebook: no notes at all, nothing typed, no filter.
    final isEmpty = total == 0 && query.isEmpty && !hasFilter;

    void newNote() => startNewNote(context);

    final Widget body;
    if (query.isNotEmpty) {
      body = _SearchResults(query: query);
    } else if (activeTag != null) {
      body = _NoteList(
        notes: ref.watch(notesWithTagProvider(activeTag)),
        empty: const _QuietEmpty(
          icon: PhosphorIconsRegular.tag,
          title: NotesStrings.tagEmpty,
          body: NotesStrings.tagEmptyBody,
        ),
      );
    } else if (activeFolder != null) {
      body = _NoteList(
        notes: ref.watch(tabletsInFolderProvider(activeFolder)),
        empty: const _QuietEmpty(
          icon: PhosphorIconsRegular.folderOpen,
          title: NotesStrings.folderEmpty,
          body: NotesStrings.folderEmptyBody,
        ),
      );
    } else if (isEmpty) {
      body = _EmptyNotes(onWrite: newNote);
    } else {
      body = _NoteList(
        notes: all,
        empty: _EmptyNotes(onWrite: newNote),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              LumSize.screenGutter + 4,
              LumSpace.xxxl,
              LumSize.screenGutter + 4,
              LumSpace.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                NotesStrings.notes,
                                maxLines: 1,
                                style: LumText.roadDisplayMedium56
                                    .copyWith(color: c.textPrimary),
                              ),
                            ),
                          ),
                          const SizedBox(height: LumSpace.xs),
                          Text(
                            shown == null ||
                                    (shown == 0 && !hasFilter && query.isEmpty)
                                ? NotesStrings.noNotesYet
                                : NotesStrings.count(shown),
                            style: LumText.subheadline
                                .copyWith(color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: LumSpace.md),
                    _NewNoteButton(onPressed: newNote),
                  ],
                ),
                if (!isEmpty) ...[
                  const SizedBox(height: LumSpace.lg),
                  SearchBarWidget(
                    controller: searchController,
                    hintText: NotesStrings.searchHint,
                    onChanged: (value) => searchQuery.value = value,
                  ),
                  const SizedBox(height: LumSpace.md),
                  _FilterRow(showActive: query.isEmpty),
                ],
              ],
            ),
          ),
        ),
        body,
      ],
    );
  }
}

/// The ink pencil button beside the title (Figma M4-01).
class _NewNoteButton extends StatelessWidget {
  const _NewNoteButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Semantics(
      button: true,
      label: NotesStrings.newNote,
      excludeSemantics: true,
      onTap: onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: c.bgPrimary, shape: BoxShape.circle),
          child: Icon(PhosphorIcons.pencilSimple(),
              size: LumSize.iconMd, color: c.textOnPrimary),
        ),
      ),
    );
  }
}

/// Filter chip plus, when a folder or tag is active, a selected chip naming it
/// (tap to clear). Reuses the existing folder and tag filter sheet.
class _FilterRow extends ConsumerWidget {
  const _FilterRow({required this.showActive});

  /// The active-filter chip is hidden while a search is typed (search wins).
  final bool showActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Wrap(
      spacing: LumSpace.sm,
      runSpacing: LumSpace.sm,
      children: [
        LumChip(
          label: NotesStrings.filter,
          icon: PhosphorIcons.funnel(),
          onTap: () => showModalBottomSheet<void>(
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
        if (label != null && showActive)
          LumChip(
            label: label,
            selected: true,
            onTap: () {
              ref.read(activeFolderProvider.notifier).state = null;
              ref.read(activeTagProvider.notifier).state = null;
            },
          ),
      ],
    );
  }
}

/// Loading, error, empty or the stack of note cards, as a sliver.
class _NoteList extends ConsumerWidget {
  const _NoteList({required this.notes, required this.empty});

  final AsyncValue<List<Note>> notes;
  final Widget empty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return notes.when(
      loading: () => const _Centered(child: CircularProgressIndicator()),
      error: (err, _) => _Centered(
        child: Text(NotesStrings.loadError(err),
            textAlign: TextAlign.center,
            style: LumText.body.copyWith(color: context.lum.textPrimary)),
      ),
      data: (list) {
        if (list.isEmpty) return empty;
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              LumSize.screenGutter, 0, LumSize.screenGutter, 150),
          sliver: SliverList.separated(
            itemCount: list.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: LumSpace.md),
            itemBuilder: (context, i) =>
                i == list.length ? const _SavedLine() : NoteCard(note: list[i]),
          ),
        );
      },
    );
  }
}

/// Quiet closing line: notes live on the device.
class _SavedLine extends StatelessWidget {
  const _SavedLine();

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Padding(
      padding: const EdgeInsets.only(top: LumSpace.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: c.iconSuccess, shape: BoxShape.circle)),
          const SizedBox(width: LumSpace.sm),
          Flexible(
            child: Text(NotesStrings.savedOnPhone,
                style: LumText.footnote.copyWith(color: c.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: child),
      );
}

/// Debounced full-text search results for the current query.
class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lum;
    return ref.watch(tabletSearchProvider(query)).when(
          loading: () => const _Centered(child: CircularProgressIndicator()),
          error: (err, _) => _Centered(
            child: Text(NotesStrings.searchFailed(err),
                textAlign: TextAlign.center,
                style: LumText.body.copyWith(color: c.textPrimary)),
          ),
          data: (hits) {
            if (hits.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: _QuietEmptyBody(
                  icon: PhosphorIcons.magnifyingGlass(),
                  title: NotesStrings.noMatches(query),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  LumSize.screenGutter, 0, LumSize.screenGutter, 150),
              sliver: SliverList.separated(
                itemCount: hits.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: LumSpace.md),
                itemBuilder: (context, i) => _SearchHitCard(hit: hits[i]),
              ),
            );
          },
        );
  }
}

/// One card surface shared by list and search rows.
class _CardShell extends StatelessWidget {
  const _CardShell(
      {required this.label, required this.onTap, required this.child});

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: LumSize.rowMin),
          padding: const EdgeInsets.all(LumSpace.lg),
          decoration: LumGroupCard.decoration(c),
          child: child,
        ),
      ),
    );
  }
}

/// A search hit: title plus the highlighted snippet from FTS5.
class _SearchHitCard extends StatelessWidget {
  const _SearchHitCard({required this.hit});

  final NoteSearchHit hit;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    final note = hit.note;
    final title =
        note.title.trim().isEmpty ? NotesStrings.untitled : note.title.trim();
    final snippet = hit.snippet.replaceAll(RegExp(r'\s+'), ' ').trim();
    return _CardShell(
      label: title,
      onTap: () => context.router.push(TabletEditorRoute(noteId: note.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: LumText.headline.copyWith(color: c.textPrimary)),
          if (snippet.isNotEmpty) ...[
            const SizedBox(height: LumSpace.xs),
            Text(snippet,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: LumText.subheadline.copyWith(color: c.textSecondary)),
          ],
        ],
      ),
    );
  }
}

/// A note in the list: title, preview, tags and when it was last touched.
/// Swipe left to delete.
class NoteCard extends ConsumerWidget {
  const NoteCard({super.key, required this.note, this.now});

  final Note note;

  /// Clock for the date label; tests pin it.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lum;
    final title =
        note.title.trim().isEmpty ? NotesStrings.untitled : note.title.trim();
    final preview = notePreviewText(note.contentMarkdown);
    final imagePath = notePreviewImage(note.contentMarkdown);
    final hasAudio = imagePath == null && noteHasAudio(note.contentMarkdown);
    final tags =
        ref.watch(tagsForNoteProvider(note.id)).valueOrNull ?? const [];
    final secondary = preview.isNotEmpty
        ? preview
        : (hasAudio
            ? NotesStrings.voiceNote
            : (imagePath != null ? NotesStrings.photo : ''));

    final repo = ref.read(tabletsRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    void delete() {
      repo.deleteNote(note.id);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: const Text(NotesStrings.noteDeleted),
          action: SnackBarAction(
            label: NotesStrings.undo,
            onPressed: () => repo.restoreNote(note.id),
          ),
        ));
    }

    return Semantics(
      customSemanticsActions: {
        const CustomSemanticsAction(label: NotesStrings.deleteNote): delete,
      },
      child: Dismissible(
        key: ValueKey(note.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: LumSpace.xl),
          decoration: BoxDecoration(
            color: c.bgDangerContainer,
            borderRadius: BorderRadius.circular(LumRadius.xl),
          ),
          child: Icon(PhosphorIcons.trash(), color: c.textOnDangerContainer),
        ),
        onDismissed: (_) => delete(),
        child: _CardShell(
          label: title,
          onTap: () => context.router.push(TabletEditorRoute(noteId: note.id)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imagePath != null || hasAudio) ...[
                _Thumb(path: imagePath),
                const SizedBox(width: LumSpace.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: LumText.headline.copyWith(color: c.textPrimary)),
                    if (secondary.isNotEmpty) ...[
                      const SizedBox(height: LumSpace.xs),
                      Text(secondary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: LumText.subheadline
                              .copyWith(color: c.textSecondary)),
                    ],
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: LumSpace.sm),
                      Wrap(
                        spacing: LumSpace.sm,
                        runSpacing: LumSpace.xs,
                        children: [
                          for (final tag in tags)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: LumSpace.md, vertical: 4),
                              decoration: BoxDecoration(
                                color: c.bgAccentContainer,
                                borderRadius:
                                    BorderRadius.circular(LumRadius.full),
                              ),
                              child: Text('#${tag.name}',
                                  style: LumText.footnoteEmphasized.copyWith(
                                      color: c.textOnAccentContainer)),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: LumSpace.sm),
                    Text(
                        noteDateLabel(
                          note.updatedAt,
                          now ?? DateTime.now(),
                          use24Hour:
                              MediaQuery.alwaysUse24HourFormatOf(context),
                        ),
                        style:
                            LumText.footnote.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Square thumbnail: the first image, or a microphone tile for voice notes.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    final p = path;
    final tile = Container(
      color: c.bgSurfaceSunken,
      child: Icon(
          p == null ? PhosphorIcons.microphone() : PhosphorIcons.imageBroken(),
          size: 22,
          color: c.iconSecondary),
    );
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(LumRadius.md),
        child: SizedBox(
          width: 56,
          height: 56,
          child: p == null
              ? tile
              : p.startsWith('http')
                  ? Image.network(p, fit: BoxFit.cover)
                  : Image.file(File(p),
                      fit: BoxFit.cover, errorBuilder: (_, __, ___) => tile),
        ),
      ),
    );
  }
}

/// Folder or tag with nothing in it.
class _QuietEmpty extends StatelessWidget {
  const _QuietEmpty(
      {required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => SliverFillRemaining(
        hasScrollBody: false,
        child: _QuietEmptyBody(icon: icon, title: title, body: body),
      );
}

class _QuietEmptyBody extends StatelessWidget {
  const _QuietEmptyBody({required this.icon, required this.title, this.body});

  final IconData icon;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LumSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: c.iconSecondary),
            const SizedBox(height: LumSpace.md),
            Text(title,
                textAlign: TextAlign.center,
                style: LumText.headline.copyWith(color: c.textPrimary)),
            if (body != null) ...[
              const SizedBox(height: LumSpace.xs),
              Text(body!,
                  textAlign: TextAlign.center,
                  style: LumText.subheadline.copyWith(color: c.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }
}

/// First-run empty state (Figma M4-03): the road, a promise, one clear action.
class _EmptyNotes extends ConsumerWidget {
  const _EmptyNotes({required this.onWrite});

  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lum;
    final hintSeen = ref.watch(templateHintSeenProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
          LumSize.screenGutter + 4, 0, LumSize.screenGutter + 4, 150),
      sliver: SliverList.list(
        children: [
          ExcludeSemantics(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(LumRadius.lg),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: Image.asset(
                  'assets/images/road/bg_${dark ? 'dark' : 'light'}.png',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, 0.35),
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          const SizedBox(height: LumSpace.xl),
          Semantics(
            header: true,
            child: Text(NotesStrings.emptyTitle,
                style: LumText.title1.copyWith(color: c.textPrimary)),
          ),
          const SizedBox(height: LumSpace.sm),
          Text(NotesStrings.emptyBody,
              style: LumText.body.copyWith(color: c.textSecondary)),
          if (!hintSeen) ...[
            const SizedBox(height: LumSpace.lg),
            Container(
              padding: const EdgeInsets.only(left: LumSpace.lg),
              decoration: BoxDecoration(
                color: c.bgAccentContainer,
                borderRadius: BorderRadius.circular(LumRadius.md),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(NotesStrings.emptyTemplateHint,
                        style: LumText.subheadline
                            .copyWith(color: c.textOnAccentContainer)),
                  ),
                  IconButton(
                    tooltip: NotesStrings.dismiss,
                    constraints:
                        const BoxConstraints(minWidth: 44, minHeight: 44),
                    icon: Icon(PhosphorIcons.x(),
                        size: 18, color: c.textOnAccentContainer),
                    onPressed: () =>
                        ref.read(templateHintSeenProvider.notifier).dismiss(),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: LumSpace.xl),
          LumButton(
            label: NotesStrings.writeNote,
            icon: Icon(PhosphorIcons.pencilSimple()),
            onPressed: onWrite,
          ),
          const SizedBox(height: LumSpace.xl),
          Text(NotesStrings.freeAndLocal,
              style: LumText.footnote.copyWith(color: c.textSecondary)),
        ],
      ),
    );
  }
}
