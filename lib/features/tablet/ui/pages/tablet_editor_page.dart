import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:auto_route/auto_route.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/audio/audio_quality_provider.dart';
import 'package:openbaptisthymnal/core/providers/service_providers.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/theme/font_scale_provider.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/utils/services/file_storage_service.dart';
import 'package:openbaptisthymnal/core/widgets/lum_circle_button.dart';
import 'package:openbaptisthymnal/core/widgets/lum_glass_bar.dart';
import 'package:openbaptisthymnal/core/widgets/lum_page_background.dart';
import 'package:openbaptisthymnal/features/bible/ui/open_bible_link.dart';
import 'package:openbaptisthymnal/features/hymn/ui/open_hymn_link.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openbaptisthymnal/features/tablet/domain/insert_media_node.dart';
import 'package:openbaptisthymnal/features/tablet/domain/note_media.dart';
import 'package:openbaptisthymnal/features/tablet/domain/link_autocomplete.dart';
import 'package:openbaptisthymnal/features/tablet/domain/note_date_label.dart';
import 'package:openbaptisthymnal/features/tablet/domain/parse_links.dart';
import 'package:openbaptisthymnal/features/tablet/domain/tablet_markdown_codec.dart';
import 'package:openbaptisthymnal/features/tablet/providers/tablets_providers.dart';
import 'package:openbaptisthymnal/features/tablet/ui/notes_strings.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/audio_recorder_sheet.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/folder_picker_sheet.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/link_suggestions.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/note_media_block.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/note_media_sheet.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/wikilink_spans.dart';
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
                body: Center(child: Text(NotesStrings.noteNotFound)),
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
    final lum = context.lum;
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
          await openHymnLink(
            context,
            ref,
            targetKey: link.targetKey,
            editionPin: link.editionPin,
          );
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

    Future<void> insertImage(ImageSource source) async {
      // Capture the caret before the picker steals focus; restore it so the
      // image lands where the user was editing.
      final sel = editorState.selection;
      final String? relativePath;
      try {
        relativePath = await ref
            .read(fileStorageServiceProvider)
            .pickAndPersistImage(bucket: 'note_images', source: source);
      } on PlatformException {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(source == ImageSource.camera
              ? NotesStrings.cameraDenied
              : NotesStrings.photosDenied),
        ));
        return;
      }
      if (relativePath == null) return;
      if (sel != null) editorState.selection = sel;
      // The live document needs the absolute path; the codec rewrites it back
      // to relative on save.
      await insertMediaNode(
        editorState,
        imageMediaNode(url: FileStorageService.absolutePath(relativePath)),
        anchorPath: _anchorPath(editorState, sel),
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
      final clip = await showModalBottomSheet<RecordedClip>(
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
      if (clip == null) return;
      final relativePath = await ref
          .read(fileStorageServiceProvider)
          .persistFile(clip.path, bucket: 'note_audio');

      await insertMediaNode(
        editorState,
        audioMediaNode(
          url: FileStorageService.absolutePath(relativePath),
          name: defaultRecordingName(DateTime.now()),
          durationMs: clip.durationMs,
          peaks: clip.peaks,
        ),
        anchorPath: _anchorPath(editorState, sel),
      );
    }

    Future<void> openInsertSheet() async {
      final choice = await showInsertSheet(context);
      if (choice == null) return;
      switch (choice) {
        case InsertChoice.camera:
          await insertImage(ImageSource.camera);
        case InsertChoice.photos:
          await insertImage(ImageSource.gallery);
        case InsertChoice.record:
          await insertAudio();
        case InsertChoice.checklist:
          if (context.mounted) {
            todoListMobileToolbarItem.actionHandler?.call(context, editorState);
          }
      }
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
      final children = wikilinkSpans(context, raw, baseStyle, navigateToLink);
      if (children.isEmpty) return before;
      return TextSpan(style: baseStyle, children: children);
    }

    final editorStyle = EditorStyle.mobile(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      cursorColor: lum.textAccent,
      selectionColor: lum.textAccent.withValues(alpha: 0.2),
      textSpanDecorator: decorateWikilinks,
      textStyleConfiguration: TextStyleConfiguration(
        text: LumText.body.copyWith(
          fontSize: 17 * textScale,
          height: 1.55,
          color: lum.textPrimary,
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

    final titleStyle = LumText.title1.copyWith(
      fontSize: 28 * textScale,
      color: lum.textPrimary,
    );
    final titleField = Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${noteDateLabel(initialCreatedAt ?? DateTime.now(), DateTime.now())}'
            ' · ${NotesStrings.savedOnPhone}',
            style: LumText.footnote.copyWith(color: lum.textSecondary),
          ),
          const SizedBox(height: LumSpace.xs),
          Semantics(
            textField: true,
            label: NotesStrings.titleHint,
            child: TextField(
              controller: titleController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: null,
              style: titleStyle,
              decoration: noBorder.copyWith(
                hintText: NotesStrings.titleHint,
                hintStyle: titleStyle.copyWith(color: lum.textDisabled),
              ),
            ),
          ),
        ],
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
      actionItem(PhosphorIcons.plusCircle(), openInsertSheet),
      actionItem(PhosphorIcons.clipboardText(), insertPasteText),
    ];

    final mediaBuilder = NoteMediaBlockBuilder(
      editorState: editorState,
      storage: ref.read(fileStorageServiceProvider),
      onLink: navigateToLink,
    );

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) save();
      },
      child: LumPageBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(LumSize.touchTarget + 24),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    LumSize.screenGutter, LumSpace.md, LumSize.screenGutter, 0),
                child: Row(
                  children: [
                    LumCircleButton(
                      icon: PhosphorIcons.caretLeft(),
                      label: NotesStrings.back,
                      onPressed: () => context.router.maybePop(),
                    ),
                    const Spacer(),
                    LumGlassBar(
                      height: LumSize.touchTarget,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LumCircleButton(
                            plain: true,
                            icon: PhosphorIcons.folder(),
                            label: NotesStrings.moveToFolder,
                            onPressed: () async {
                              await save();
                              final id = currentId.value;
                              if (id == null || !context.mounted) return;
                              showModalBottomSheet<void>(
                                context: context,
                                showDragHandle: true,
                                builder: (_) => FolderPickerSheet(noteId: id),
                              );
                            },
                          ),
                          LumCircleButton(
                            plain: true,
                            icon: PhosphorIcons.tag(),
                            label: NotesStrings.noteTags,
                            onPressed: () async {
                              await save();
                              final id = currentId.value;
                              if (id == null || !context.mounted) return;
                              showModalBottomSheet<void>(
                                context: context,
                                showDragHandle: true,
                                builder: (_) => TagPickerSheet(noteId: id),
                              );
                            },
                          ),
                          LumCircleButton(
                            plain: true,
                            icon: PhosphorIcons.treeStructure(),
                            label: NotesStrings.linksAndBacklinks,
                            onPressed: () async {
                              await save();
                              if (!context.mounted) return;
                              showModalBottomSheet<void>(
                                context: context,
                                showDragHandle: true,
                                isScrollControlled: true,
                                builder: (_) => NoteLinksSheet(
                                  markdown: noteDocumentToMarkdown(
                                      editorState.document),
                                  title: titleController.text.trim(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: SafeArea(
            child: MobileToolbarV2(
              editorState: editorState,
              toolbarItems: toolbarItems,
              backgroundColor: lum.glassFillOpaque,
              foregroundColor: lum.textSecondary,
              iconColor: lum.textPrimary,
              primaryColor: lum.bgPrimary,
              outlineColor: lum.borderSubtle,
              itemOutlineColor: lum.borderSubtle,
              child: Stack(
                children: [
                  AppFlowyEditor(
                    editorState: editorState,
                    editorStyle: editorStyle,
                    autoFocus: noteId == null,
                    header: titleField,
                    blockComponentBuilders: {
                      ...standardBlockComponentBuilderMap,
                      ImageBlockKeys.type: mediaBuilder,
                      audioNodeType: mediaBuilder,
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
      ),
    );
  }
}

/// Where a new media block goes: the caret's block, else the last one.
List<int> _anchorPath(EditorState editorState, Selection? sel) =>
    (sel ?? editorState.selection)?.end.path ??
    editorState.document.root.children.last.path;
