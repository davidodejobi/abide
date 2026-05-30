import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/features/notes/domain/link_autocomplete.dart';
import 'package:openbaptisthymnal/features/notes/domain/markdown_spans.dart';
import 'package:openbaptisthymnal/features/notes/domain/parse_links.dart';
import 'package:openbaptisthymnal/features/notes/providers/notes_providers.dart';
import 'package:openbaptisthymnal/features/notes/ui/widgets/link_suggestions.dart';
import 'package:openbaptisthymnal/features/notes/ui/widgets/note_editing_controller.dart';
import 'package:openbaptisthymnal/features/notes/ui/widgets/note_format_toolbar.dart';
import 'package:openbaptisthymnal/features/notes/ui/widgets/note_links_sheet.dart';

/// Create / edit a single note. Markdown is the source of truth and rendered
/// with live inline styling (links, bold, italics, headings) as the user types.
@RoutePage()
class NoteEditorPage extends HookConsumerWidget {
  const NoteEditorPage({super.key, this.noteId});

  final String? noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final titleController = useTextEditingController();
    final currentId = useState<String?>(noteId);
    final createdAt = useRef<DateTime?>(null);
    final seeded = useRef(false);
    final linkQuery = useState<String?>(null);

    Future<void> navigateToLink(ParsedLink link) async {
      switch (link.type) {
        case NoteLinkType.hymn:
          context.router.push(HymnDetailRoute(hymnId: link.targetKey));
        case NoteLinkType.bible:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bible reading is coming soon.')),
          );
        case NoteLinkType.note:
          final notes = ref.read(notesListProvider).valueOrNull ?? [];
          final match = notes
              .where(
                  (n) => n.title.toLowerCase() == link.targetKey.toLowerCase())
              .firstOrNull;
          // Obsidian-style: a link to a note that doesn't exist yet creates it,
          // using the link text as the title, then opens the new note.
          final targetId = match?.id ??
              await ref.read(notesRepositoryProvider).createNote(
                    title: link.display,
                    contentMarkdown: '',
                  );
          if (!context.mounted) return;
          context.router.push(NoteEditorRoute(noteId: targetId));
      }
    }

    final bodyController = useMemoized(NoteEditingController.new, const []);
    useEffect(() => bodyController.dispose, [bodyController]);

    // Tapping inside a rendered `[[...]]` token navigates to its target.
    // Recognizers can't live on spans in an editable field, so we detect the
    // tapped token from the caret position instead.
    void handleBodyTap() {
      final sel = bodyController.selection;
      if (!sel.isValid || !sel.isCollapsed) return;
      final offset = sel.baseOffset;
      final text = bodyController.text;
      for (final run in computeMarkdownRuns(text)) {
        if (run.type != MarkdownRunType.link) continue;
        if (offset <= run.start || offset >= run.end) continue;
        final parsed = parseLinks(text.substring(run.start, run.end));
        if (parsed.isNotEmpty) navigateToLink(parsed.first);
        return;
      }
    }

    // Track an in-progress `[[` token at the caret to drive autocomplete.
    useEffect(() {
      void listener() {
        final sel = bodyController.selection;
        linkQuery.value = sel.isValid && sel.isCollapsed
            ? linkAutocompleteQuery(bodyController.text, sel.baseOffset)
            : null;
      }

      bodyController.addListener(listener);
      return () => bodyController.removeListener(listener);
    }, [bodyController]);

    void completeLink(String token) {
      final sel = bodyController.selection;
      if (!sel.isValid) return;
      final result =
          applyLinkCompletion(bodyController.text, sel.baseOffset, token);
      bodyController.value = TextEditingValue(
        text: result.text,
        selection: TextSelection.collapsed(offset: result.cursor),
      );
      linkQuery.value = null;
    }

    // Wraps the current selection (or inserts at the caret) with markdown
    // markers, e.g. **bold** or *italic*.
    void wrapSelection(String marker) {
      final sel = bodyController.selection;
      if (!sel.isValid) return;
      final text = bodyController.text;
      final selected = text.substring(sel.start, sel.end);
      final replacement = '$marker$selected$marker';
      final caret = selected.isEmpty
          ? sel.start + marker.length
          : sel.end + marker.length * 2;
      bodyController.value = TextEditingValue(
        text: text.replaceRange(sel.start, sel.end, replacement),
        selection: TextSelection.collapsed(offset: caret),
      );
    }

    void insertLinkToken() {
      final sel = bodyController.selection;
      if (!sel.isValid) return;
      final text = bodyController.text;
      final selected = text.substring(sel.start, sel.end);
      final replacement = '[[$selected]]';
      // Place the caret just inside `[[` so autocomplete kicks in.
      final caret = sel.start + 2 + selected.length;
      bodyController.value = TextEditingValue(
        text: text.replaceRange(sel.start, sel.end, replacement),
        selection: TextSelection.collapsed(offset: caret),
      );
    }

    // Seed the fields once from an existing note.
    if (noteId != null) {
      ref.watch(noteByIdProvider(noteId!)).whenData((note) {
        if (note != null && !seeded.value) {
          seeded.value = true;
          titleController.text = note.title;
          bodyController.text = note.contentMarkdown;
          createdAt.value = note.createdAt;
        }
      });
    }

    Future<void> save() async {
      final title = titleController.text.trim();
      final body = bodyController.text;
      if (title.isEmpty && body.trim().isEmpty) return;

      final repo = ref.read(notesRepositoryProvider);
      final id = currentId.value;
      if (id == null) {
        currentId.value = await repo.createNote(
          title: title,
          contentMarkdown: body,
        );
      } else {
        await repo.updateNote(
          id: id,
          title: title,
          contentMarkdown: body,
          createdAt: createdAt.value ?? DateTime.now(),
        );
      }
    }

    // Debounced autosave: persist ~800ms after the user stops typing so we
    // don't hit SQLite (and re-sync links) on every keystroke. Save-on-exit
    // below still acts as a final flush.
    final saveDebounce = useRef<Timer?>(null);
    useEffect(() {
      void scheduleSave() {
        saveDebounce.value?.cancel();
        saveDebounce.value = Timer(const Duration(milliseconds: 800), save);
      }

      titleController.addListener(scheduleSave);
      bodyController.addListener(scheduleSave);
      return () {
        saveDebounce.value?.cancel();
        titleController.removeListener(scheduleSave);
        bodyController.removeListener(scheduleSave);
      };
    }, [bodyController]);

    const noBorder = InputDecoration(
      contentPadding: EdgeInsets.zero,
      isCollapsed: true,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      filled: false,
    );

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) save();
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.router.maybePop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.account_tree_outlined),
              tooltip: 'Links & backlinks',
              onPressed: () async {
                await save();
                if (!context.mounted) return;
                showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  isScrollControlled: true,
                  backgroundColor: theme.colorScheme.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => NoteLinksSheet(
                    markdown: bodyController.text,
                    title: titleController.text.trim(),
                  ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: titleController,
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: null,
                            style: const TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                            decoration: noBorder.copyWith(
                              hintText: 'Title',
                              hintStyle: TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: theme.hintColor.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: bodyController,
                            onTap: handleBodyTap,
                            // Add Bold/Italic/Link to the native long-press
                            // selection toolbar alongside Cut/Copy/Paste.
                            contextMenuBuilder: (context, editableState) {
                              final items = List<ContextMenuButtonItem>.of(
                                editableState.contextMenuButtonItems,
                              );
                              final sel = bodyController.selection;
                              if (sel.isValid && !sel.isCollapsed) {
                                items.insertAll(0, [
                                  ContextMenuButtonItem(
                                    label: 'Bold',
                                    onPressed: () {
                                      editableState.hideToolbar();
                                      wrapSelection('**');
                                    },
                                  ),
                                  ContextMenuButtonItem(
                                    label: 'Italic',
                                    onPressed: () {
                                      editableState.hideToolbar();
                                      wrapSelection('*');
                                    },
                                  ),
                                  ContextMenuButtonItem(
                                    label: 'Link',
                                    onPressed: () {
                                      editableState.hideToolbar();
                                      insertLinkToken();
                                    },
                                  ),
                                ]);
                              }
                              return AdaptiveTextSelectionToolbar.buttonItems(
                                anchors: editableState.contextMenuAnchors,
                                buttonItems: items,
                              );
                            },
                            maxLines: null,
                            minLines: 12,
                            keyboardType: TextInputType.multiline,
                            textCapitalization: TextCapitalization.sentences,
                            cursorColor: theme.colorScheme.primary,
                            style: const TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 17,
                              height: 1.55,
                            ),
                            decoration: noBorder.copyWith(
                              hintText: 'Start writing…  Use **bold**, '
                                  '*italics*, or [[ to link.',
                              hintStyle: TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 17,
                                height: 1.55,
                                color: theme.hintColor.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (linkQuery.value != null)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 8,
                        child: LinkSuggestions(
                          query: linkQuery.value!,
                          currentNoteId: currentId.value,
                          onSelected: completeLink,
                        ),
                      ),
                  ],
                ),
              ),
              NoteFormatToolbar(
                onBold: () => wrapSelection('**'),
                onItalic: () => wrapSelection('*'),
                onLink: insertLinkToken,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
