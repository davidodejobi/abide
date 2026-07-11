import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/audio/audio_quality_provider.dart';
import 'package:openbaptisthymnal/core/providers/service_providers.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/theme/app_colors.dart';
import 'package:openbaptisthymnal/core/theme/font_scale_provider.dart';
import 'package:openbaptisthymnal/core/utils/services/file_storage_service.dart';
import 'package:openbaptisthymnal/features/bible/ui/open_bible_link.dart';
import 'package:openbaptisthymnal/features/hymn/domain/hymn_link_resolver.dart';
import 'package:openbaptisthymnal/features/hymn/providers/hymnal_provider.dart';
import 'package:openbaptisthymnal/features/tablet/domain/insert_audio_node.dart';
import 'package:openbaptisthymnal/features/tablet/domain/link_autocomplete.dart';
import 'package:openbaptisthymnal/features/tablet/domain/parse_links.dart';
import 'package:openbaptisthymnal/features/tablet/domain/tablet_markdown_codec.dart';
import 'package:openbaptisthymnal/features/tablet/providers/tablets_providers.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/audio_block_component.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/audio_recorder_sheet.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/folder_picker_sheet.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/link_suggestions.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/tablet_links_sheet.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/tag_picker_sheet.dart';

/// Create / edit a single note. Markdown is the source of truth; the body is
/// edited in an [AppFlowyEditor] document and converted back to markdown on
/// save. `[[wikilinks]]` stay literal in the markdown and are styled + made
/// tappable at render time via the editor's `textSpanDecorator`.
///
/// The page is split in two: this loader resolves the note's initial markdown
/// (async for existing notes) before mounting [_NoteEditorView], because an
/// [EditorState]'s document is final and must be seeded once, up front.
@RoutePage()
class TabletEditorPage extends HookConsumerWidget {
  const TabletEditorPage({super.key, this.noteId, this.initialMarkdown});

  final String? noteId;

  /// Seed body for a brand-new tablet (e.g. a pre-filled `[[bible:...]]` link
  /// from the Bible reader's "Add note"). Ignored when [noteId] is non-null.
  final String? initialMarkdown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (noteId == null) {
      return _NoteEditorView(
        noteId: null,
        initialTitle: '',
        initialMarkdown: initialMarkdown ?? '',
        initialCreatedAt: null,
      );
    }

    return ref.watch(tabletByIdProvider(noteId!)).maybeWhen(
          data: (note) {
            if (note == null) {
              return const Scaffold(
                body: Center(child: Text('Tablet not found')),
              );
            }
            // Keyed by id so the editor mounts once per note and ignores later
            // stream emissions (e.g. our own autosaves) without re-seeding.
            return _NoteEditorView(
              key: ValueKey(note.id),
              noteId: note.id,
              initialTitle: note.title,
              initialMarkdown: note.contentMarkdown,
              initialCreatedAt: note.createdAt,
            );
          },
          orElse: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
  }
}

class _NoteEditorView extends HookConsumerWidget {
  const _NoteEditorView({
    required this.noteId,
    required this.initialTitle,
    required this.initialMarkdown,
    required this.initialCreatedAt,
    super.key,
  });

  final String? noteId;
  final String initialTitle;
  final String initialMarkdown;
  final DateTime? initialCreatedAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textScale = ref.watch(fontScaleProvider).scale;
    final titleController = useTextEditingController(text: initialTitle);
    final currentId = useState<String?>(noteId);
    final createdAt = useRef<DateTime?>(initialCreatedAt);
    final linkQuery = useState<String?>(null);

    // Seed the document once; the EditorState owns it for the page's lifetime.
    final editorState = useMemoized(
      () => EditorState(document: noteMarkdownToDocument(initialMarkdown)),
      const [],
    );
    useEffect(() => editorState.dispose, [editorState]);

    Future<void> navigateToLink(ParsedLink link) async {
      switch (link.type) {
        case NoteLinkType.hymn:
          final target = ref
              .read(hymnLinkResolverProvider)
              .resolve(link.targetKey, editionPin: link.editionPin);
          if (target == null) return;
          // The hymn detail page reads `languageProvider`, so set it before
          // pushing so the resolved edition is the one that opens.
          ref.read(languageProvider.notifier).state = target.editionId;
          if (!context.mounted) return;
          if (target.toastMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(target.toastMessage!)),
            );
          }
          context.router.push(HymnDetailRoute(hymnId: target.hymnId));
        case NoteLinkType.bible:
          await openBibleLink(
            context,
            ref,
            targetKey: link.targetKey,
            editionPin: link.editionPin,
          );
        case NoteLinkType.note:
          final notes = ref.read(tabletsListProvider).valueOrNull ?? [];
          final match = notes
              .where(
                  (n) => n.title.toLowerCase() == link.targetKey.toLowerCase())
              .firstOrNull;
          // Obsidian-style: linking to a note that doesn't exist yet creates
          // it from the link text, then opens it.
          final targetId = match?.id ??
              await ref.read(tabletsRepositoryProvider).createNote(
                    title: link.display,
                    contentMarkdown: '',
                  );
          if (!context.mounted) return;
          context.router.push(TabletEditorRoute(noteId: targetId));
      }
    }

    Future<void> save() async {
      final title = titleController.text.trim();
      final body = noteDocumentToMarkdown(editorState.document);
      if (title.isEmpty && body.trim().isEmpty) return;

      final repo = ref.read(tabletsRepositoryProvider);
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
    // below is the final flush.
    final saveDebounce = useRef<Timer?>(null);
    useEffect(() {
      void scheduleSave() {
        saveDebounce.value?.cancel();
        saveDebounce.value = Timer(const Duration(milliseconds: 800), save);
      }

      final sub = editorState.transactionStream.listen((_) => scheduleSave());
      titleController.addListener(scheduleSave);
      return () {
        saveDebounce.value?.cancel();
        sub.cancel();
        titleController.removeListener(scheduleSave);
      };
    }, [editorState]);

    // Track an in-progress `[[` token at the caret to drive autocomplete.
    useEffect(() {
      void update() {
        final sel = editorState.selection;
        if (sel == null || !sel.isCollapsed) {
          linkQuery.value = null;
          return;
        }
        final node = editorState.getNodeAtPath(sel.start.path);
        final text = node?.delta?.toPlainText() ?? '';
        linkQuery.value = linkAutocompleteQuery(text, sel.startIndex);
      }

      editorState.selectionNotifier.addListener(update);
      final sub = editorState.transactionStream.listen((_) => update());
      return () {
        editorState.selectionNotifier.removeListener(update);
        sub.cancel();
      };
    }, [editorState]);

    Future<void> completeLink(String token) async {
      final sel = editorState.selection;
      if (sel == null || !sel.isCollapsed) return;
      final node = editorState.getNodeAtPath(sel.start.path);
      if (node == null) return;
      final text = node.delta?.toPlainText() ?? '';
      final result = applyLinkCompletion(text, sel.startIndex, token);
      final transaction = editorState.transaction
        ..replaceText(node, 0, text.length, result.text)
        ..afterSelection = Selection.collapsed(
          Position(path: node.path, offset: result.cursor),
        );
      await editorState.apply(transaction);
      linkQuery.value = null;
    }

    Future<void> insertLinkToken() async {
      final sel = editorState.selection;
      if (sel == null || !sel.isCollapsed) return;
      await editorState.insertTextAtCurrentSelection('[[]]');
      // Place the caret just inside `[[` so autocomplete kicks in.
      editorState.selection = Selection.collapsed(
        Position(path: sel.start.path, offset: sel.startIndex + 2),
      );
    }

    Future<void> insertImage() async {
      // Capture the caret before the picker steals focus; restore it so the
      // image lands where the user was editing.
      final sel = editorState.selection;
      final relativePath = await ref
          .read(fileStorageServiceProvider)
          .pickAndPersistImage(bucket: 'note_images');
      if (relativePath == null) return;
      if (sel != null) editorState.selection = sel;
      // Live document renders via Image.file, which needs the absolute path;
      // the codec rewrites it back to relative on save.
      await editorState.insertImageNode(
        FileStorageService.absolutePath(relativePath),
      );
    }

    Future<void> insertPasteText() async {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;
      if (text == null || text.isEmpty) return;
      if (editorState.selection == null) {
        final end = editorState.document.root.children.lastOrNull;
        if (end != null) {
          final offset = end.delta?.toPlainText().length ?? 0;
          editorState.selection = Selection.collapsed(
            Position(path: end.path, offset: offset),
          );
        }
      }
      await editorState.insertTextAtCurrentSelection(text);
    }

    Future<void> insertAudio() async {
      final sel = editorState.selection;
      final tempPath = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: theme.colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => AudioRecorderSheet(
          quality: ref.read(audioQualityProvider),
        ),
      );
      if (tempPath == null) return;
      // Audio clips live as image nodes pointing at an audio file; the custom
      // block builder renders them as a player (see MediaBlockComponentBuilder).
      final relativePath = await ref
          .read(fileStorageServiceProvider)
          .persistFile(tempPath, bucket: 'note_audio');

      final anchorPath = (sel ?? editorState.selection)?.end.path ??
          editorState.document.root.children.last.path;
      await insertAudioNode(
        editorState,
        absoluteUrl: FileStorageService.absolutePath(relativePath),
        anchorPath: anchorPath,
      );
    }

    // Style every `[[...]]` token gold + underlined and make it tappable.
    // `before` already carries the run's bold/italic styling, so we reuse its
    // style as the base and only recolour the link spans.
    InlineSpan decorateWikilinks(
      BuildContext context,
      Node node,
      int index,
      TextInsert text,
      TextSpan before,
      TextSpan after,
    ) {
      final raw = before.text ?? text.text;
      final baseStyle = before.style;
      if (!raw.contains('[[')) return before;
      final matches = RegExp(r'\[\[[^\[\]]*\]\]').allMatches(raw).toList();
      if (matches.isEmpty) return before;

      final children = <InlineSpan>[];
      var cursor = 0;
      for (final m in matches) {
        if (m.start > cursor) {
          children.add(
            TextSpan(text: raw.substring(cursor, m.start), style: baseStyle),
          );
        }
        final token = raw.substring(m.start, m.end);
        final parsed = parseLinks(token);
        children.add(TextSpan(
          text: token,
          style: (baseStyle ?? const TextStyle()).copyWith(
            color: AppColors.secondary,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.secondary,
          ),
          recognizer: parsed.isEmpty
              ? null
              : (TapGestureRecognizer()
                ..onTap = () => navigateToLink(parsed.first)),
        ));
        cursor = m.end;
      }
      if (cursor < raw.length) {
        children.add(TextSpan(text: raw.substring(cursor), style: baseStyle));
      }
      return TextSpan(style: baseStyle, children: children);
    }

    final editorStyle = EditorStyle.mobile(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      cursorColor: theme.colorScheme.primary,
      selectionColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      textSpanDecorator: decorateWikilinks,
      textStyleConfiguration: TextStyleConfiguration(
        text: TextStyle(
          fontFamily: 'Geist',
          fontSize: 17 * textScale,
          height: 1.55,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );

    const noBorder = InputDecoration(
      contentPadding: EdgeInsets.zero,
      isCollapsed: true,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      filled: false,
    );

    final titleField = Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
      child: TextField(
        controller: titleController,
        textCapitalization: TextCapitalization.sentences,
        maxLines: null,
        style: TextStyle(
          fontFamily: 'Geist',
          fontSize: 28 * textScale,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        decoration: noBorder.copyWith(
          hintText: 'Title',
          hintStyle: TextStyle(
            fontFamily: 'Geist',
            fontSize: 28 * textScale,
            fontWeight: FontWeight.w700,
            color: theme.hintColor.withValues(alpha: 0.4),
          ),
        ),
      ),
    );

    MobileToolbarItem actionItem(IconData icon, VoidCallback onTap) =>
        MobileToolbarItem.action(
          itemIconBuilder: (context, _, __) => Icon(
            icon,
            color: MobileToolbarTheme.of(context).iconColor,
          ),
          actionHandler: (_, __) => onTap(),
        );

    // Selection toolbar docked above the keyboard. Block items (heading/list/
    // quote/divider) and the inline decoration item all round-trip through our
    // markdown codec, so anything inserted here survives a save.
    final toolbarItems = <MobileToolbarItem>[
      textDecorationMobileToolbarItemV2,
      headingMobileToolbarItem,
      todoListMobileToolbarItem,
      listMobileToolbarItem,
      quoteMobileToolbarItem,
      dividerMobileToolbarItem,
      actionItem(PhosphorIcons.linkSimple(), insertLinkToken),
      actionItem(PhosphorIcons.image(), insertImage),
      actionItem(PhosphorIcons.microphone(), insertAudio),
      actionItem(PhosphorIcons.clipboardText(), insertPasteText),
    ];

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) save();
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          actions: [
            IconButton(
              icon: Icon(PhosphorIcons.folder()),
              tooltip: 'Move to folder',
              onPressed: () async {
                await save();
                final id = currentId.value;
                if (id == null || !context.mounted) return;
                showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  backgroundColor: theme.colorScheme.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => FolderPickerSheet(noteId: id),
                );
              },
            ),
            IconButton(
              icon: Icon(PhosphorIcons.tag()),
              tooltip: 'Tags',
              onPressed: () async {
                await save();
                final id = currentId.value;
                if (id == null || !context.mounted) return;
                showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  backgroundColor: theme.colorScheme.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => TagPickerSheet(noteId: id),
                );
              },
            ),
            IconButton(
              icon: Icon(PhosphorIcons.treeStructure()),
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
                    markdown: noteDocumentToMarkdown(editorState.document),
                    title: titleController.text.trim(),
                  ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: MobileToolbarV2(
            editorState: editorState,
            toolbarItems: toolbarItems,
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.onSurfaceVariant,
            iconColor: theme.colorScheme.onSurface,
            primaryColor: theme.colorScheme.primary,
            outlineColor: theme.colorScheme.outlineVariant,
            itemOutlineColor: theme.colorScheme.outlineVariant,
            child: Stack(
              children: [
                AppFlowyEditor(
                  editorState: editorState,
                  editorStyle: editorStyle,
                  autoFocus: noteId == null,
                  header: titleField,
                  blockComponentBuilders: {
                    ...standardBlockComponentBuilderMap,
                    ImageBlockKeys.type:
                        MediaBlockComponentBuilder(editorState: editorState),
                  },
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
        ),
      ),
    );
  }
}
