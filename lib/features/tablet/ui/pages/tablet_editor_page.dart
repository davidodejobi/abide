import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:auto_route/auto_route.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/providers/service_providers.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/theme/font_scale_provider.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/utils/services/file_storage_service.dart';
import 'package:openbaptisthymnal/core/widgets/lum_circle_button.dart';
import 'package:openbaptisthymnal/core/widgets/lum_glass_bar.dart';
import 'package:openbaptisthymnal/core/widgets/lum_page_background.dart';
import 'package:openbaptisthymnal/features/bible/ui/open_bible_link.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';
import 'package:openbaptisthymnal/features/hymn/ui/open_hymn_link.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openbaptisthymnal/features/tablet/domain/insert_media_node.dart';
import 'package:openbaptisthymnal/features/tablet/domain/note_media.dart';
import 'package:openbaptisthymnal/features/tablet/domain/link_autocomplete.dart';
import 'package:openbaptisthymnal/features/tablet/domain/note_date_label.dart';
import 'package:openbaptisthymnal/features/tablet/domain/note_template.dart';
import 'package:openbaptisthymnal/features/tablet/domain/parse_links.dart';
import 'package:openbaptisthymnal/features/tablet/domain/recording_note.dart';
import 'package:openbaptisthymnal/features/tablet/domain/scripture_autolink.dart';
import 'package:openbaptisthymnal/features/tablet/domain/template_to_note.dart';
import 'package:openbaptisthymnal/features/tablet/domain/tablet_markdown_codec.dart';
import 'package:openbaptisthymnal/features/tablet/providers/recording_providers.dart';
import 'package:openbaptisthymnal/features/tablet/providers/tablets_providers.dart';
import 'package:openbaptisthymnal/features/tablet/providers/templates_providers.dart';
import 'package:openbaptisthymnal/features/tablet/ui/notes_strings.dart';
import 'package:openbaptisthymnal/features/tablet/ui/pages/recording_page.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/folder_picker_sheet.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/link_suggestions.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/note_media_block.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/note_media_sheet.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/note_player_bar.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/template_sheets.dart';
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
  const TabletEditorPage(
      {super.key, this.noteId, this.initialMarkdown, this.templateId});

  final String? noteId;

  /// Seed body for a brand-new tablet (e.g. a pre-filled `[[bible:...]]` link
  /// from the Bible reader's "Add note"). Ignored when [noteId] is non-null.
  final String? initialMarkdown;

  /// Start the new note from this template (built-in or mine). Ignored when
  /// [noteId] is non-null: notes are snapshots, they never re-read a template.
  final String? templateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (noteId == null) {
      final id = templateId;
      final template = id == null ? null : ref.watch(templateByIdProvider(id));
      // "Mine" arrives from a stream; wait for it rather than open blank.
      if (id != null &&
          template == null &&
          ref.watch(myTemplatesProvider).isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return _NoteEditorView(
        noteId: null,
        initialTitle: '',
        initialMarkdown: initialMarkdown ?? '',
        initialCreatedAt: null,
        template: template,
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
    this.template,
    super.key,
  });

  final String? noteId;
  final String initialTitle;
  final String initialMarkdown;
  final DateTime? initialCreatedAt;

  /// Seeds a new note's body; null for blank notes and existing ones.
  final NoteTemplate? template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lum = context.lum;
    final textScale = ref.watch(fontScaleProvider).scale;
    final titleController = useTextEditingController(text: initialTitle);
    final currentId = useState<String?>(noteId);
    final createdAt = useRef<DateTime?>(initialCreatedAt);
    final linkQuery = useState<String?>(null);

    // Seed the document once; the EditorState owns it for the page's lifetime.
    final seeded = useMemoized(() {
      final t = template;
      if (t == null) {
        return (
          editor: EditorState(document: noteMarkdownToDocument(initialMarkdown)),
          untouched: null as String?,
        );
      }
      final editor = EditorState(
        document: templateToDocument(
          t,
          now: DateTime.now(),
          lastSpeaker: ref.read(lastSpeakerProvider),
        ),
      );
      return (editor: editor, untouched: noteDocumentToMarkdown(editor.document));
    }, const []);
    final editorState = seeded.editor;
    // The delete-undo snackbar must not outlive the editor: its Undo would act
    // on a disposed document.
    final messenger = ScaffoldMessenger.of(context);
    useEffect(() {
      return () {
        messenger.hideCurrentSnackBar();
        editorState.dispose();
      };
    }, [editorState]);

    // The note's recording drives the pinned player and `t:` links. Nothing
    // here touches the shared player until the user acts, so opening a note
    // never mutates a provider while building, and coming back to a note
    // re-loads its clip on the next tap.
    final playback = ref.read(notePlaybackProvider.notifier);
    final markerSeconds = useState<List<int>>(const []);
    final firstAudio = useState<({String path, int ms, int speed})?>(null);
    final loadedPaths = useRef(<String>{});

    void loadAudio(Node audio) {
      final path = audio.attributes[mediaUrlKey] as String? ?? '';
      loadedPaths.value.add(path);
      playback.load(
        path,
        durationMs: audio.attributes[audioDurationKey] as int? ?? 0,
        speed: audio.attributes[audioSpeedKey] as int? ?? 100,
      );
    }

    useEffect(() {
      var disposed = false;
      void sync() {
        if (disposed) return;
        final audio = firstAudioNode(editorState.document);
        final next = audio == null
            ? null
            : (
                path: audio.attributes[mediaUrlKey] as String? ?? '',
                ms: audio.attributes[audioDurationKey] as int? ?? 0,
                speed: audio.attributes[audioSpeedKey] as int? ?? 100,
              );
        final prev = firstAudio.value;
        if (prev != null && next == null) playback.releaseIf(prev.path);
        firstAudio.value = next;
        final marks = timeLinkSecondsIn(editorState.document);
        if (!listEquals(marks, markerSeconds.value)) markerSeconds.value = marks;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) => sync());
      final sub = editorState.transactionStream
          .where((e) => e.$1 == TransactionTime.after)
          .listen((_) => sync());
      return () {
        disposed = true;
        sub.cancel();
        for (final path in loadedPaths.value) {
          playback.releaseIf(path);
        }
      };
    }, [editorState]);

    // Land the caret in the title of a template note, not the first field.
    final titleFocus = useFocusNode();
    useEffect(() {
      if (template != null) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => titleFocus.requestFocus());
      }
      return null;
    }, const []);

    // Auto-link "John 3:16" typed in the body once the Bible index is loaded.
    final manifestRef = useRef<BibleManifest?>(null);
    manifestRef.value = ref.watch(bibleManifestProvider('en-kjv')).valueOrNull;
    useEffect(() {
      final linker = ScriptureAutoLinker(editorState, () => manifestRef.value);
      final sub = editorState.transactionStream
          .where((e) => e.$1 == TransactionTime.after)
          .listen((_) => linker.onTransaction());
      return sub.cancel;
    }, [editorState]);

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
      // A template note the user has not touched yet is not worth saving.
      if (currentId.value == null &&
          title.isEmpty &&
          body == seeded.untouched) {
        return;
      }

      final repo = ref.read(tabletsRepositoryProvider);
      final id = currentId.value;
      if (id == null) {
        currentId.value = await repo.createNote(
          title: title,
          contentMarkdown: body,
        );
        unawaited(ref.read(templateHintSeenProvider.notifier).dismiss());
      } else {
        await repo.updateNote(
          id: id,
          title: title,
          contentMarkdown: body,
          createdAt: createdAt.value ?? DateTime.now(),
        );
      }
      if (template != null) {
        final speaker = lastSpeakerFrom(body);
        if (speaker != null) {
          unawaited(ref.read(lastSpeakerProvider.notifier).remember(speaker));
        }
      }
    }

    Future<void> saveAsTemplate() async {
      var sections = documentToSections(editorState.document);
      if (template != null) {
        sections = restoreTemplateHints(sections, template!);
      }
      if (sections.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(NotesStrings.noSectionsToSave)));
        return;
      }
      context.router.push(TemplateEditorRoute(
        initialName: titleController.text.trim(),
        initialIcon: template?.icon ?? 'book',
        initialSections: sections,
      ));
    }

    Future<void> openNoteMenu() async {
      final choice = await showModalBottomSheet<bool>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SheetRow(
                icon: PhosphorIcons.copy(),
                title: NotesStrings.saveAsTemplate,
                onTap: () => Navigator.of(sheetContext).pop(true),
              ),
              const SizedBox(height: LumSpace.sm),
            ],
          ),
        ),
      );
      if (choice == true) await saveAsTemplate();
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

    Future<void> insertImage(ImageSource source, Selection? sel) async {
      // `sel` is the caret captured before the Insert sheet stole focus.
      final String? relativePath;
      try {
        relativePath = await ref
            .read(fileStorageServiceProvider)
            .pickAndPersistImage(bucket: 'note_images', source: source);
      } on PlatformException catch (e) {
        if (!context.mounted) return;
        final String message;
        if (e.code == 'no_available_camera') {
          message = NotesStrings.noCamera;
        } else if (source == ImageSource.camera) {
          message = NotesStrings.cameraDenied;
        } else {
          message = NotesStrings.photosDenied;
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
        return;
      }
      if (relativePath == null) return;
      if (sel != null) editorState.selection = sel;
      // The live document needs the absolute path; the codec rewrites it back
      // to relative on save.
      await insertMediaNode(
        editorState,
        imageMediaNode(url: FileStorageService.absolutePath(relativePath)),
        anchorPath: mediaAnchorPath(editorState, sel),
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
      final storage = ref.read(fileStorageServiceProvider);
      final repo = ref.read(tabletsRepositoryProvider);
      final messenger = ScaffoldMessenger.of(context);
      final result = await openRecorder(context);
      if (result == null) return;
      try {
        final nodes = await persistRecording(storage, result);
        if (!context.mounted) {
          // The note closed while recording: keep the take in a new note.
          await repo.createNote(
            title: result.name,
            contentMarkdown: noteDocumentToMarkdown(
                Document(root: pageNode(children: nodes))),
          );
          return;
        }
        if (titleController.text.trim().isEmpty) {
          titleController.text = result.name;
        }
        // The first take heads the note; later ones follow the last take and
        // its markers.
        await editorState.apply(editorState.transaction
          ..insertNodes([recordingInsertIndex(editorState.document)], nodes));
      } catch (_) {
        messenger.showSnackBar(
            const SnackBar(content: Text(NotesStrings.saveFailed)));
      }
    }

    Future<void> openInsertSheet() async {
      // The sheet steals focus and clears the selection: keep the caret.
      final sel = editorState.selection;
      final choice = await showInsertSheet(context);
      if (choice == null) return;
      switch (choice) {
        case InsertChoice.camera:
          await insertImage(ImageSource.camera, sel);
        case InsertChoice.photos:
          await insertImage(ImageSource.gallery, sel);
        case InsertChoice.record:
          await insertAudio();
        case InsertChoice.checklist:
          if (sel != null) editorState.selection = sel;
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
      final seconds =
          timeLinkSeconds(text.attributes?[AppFlowyRichTextKeys.href] as String?);
      if (seconds != null) {
        final audio = audioNodeAbove(editorState.document, node.path);
        // `[05:12](t:312)`: seeks the note's recording, never opens a URL.
        return TextSpan(
          text: raw,
          style: (baseStyle ?? const TextStyle()).copyWith(
            color: lum.textAccent,
            decoration: TextDecoration.underline,
            decorationColor: lum.textAccent,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              if (audio == null) return;
              loadAudio(audio);
              playback.seekAndPlay(seconds);
            },
        );
      }
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
              focusNode: titleFocus,
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

    // A template's hints are placeholders on the empty blocks, never text:
    // nothing here reaches the markdown, the search index or sync.
    final hints = template == null ? const <String, String>{} : templateHints(template!);
    final templateBuilders = <String, BlockComponentBuilder>{
      if (hints.isNotEmpty) ...{
        ParagraphBlockKeys.type: ParagraphBlockComponentBuilder(
          configuration: standardBlockComponentConfiguration.copyWith(
            placeholderText: (n) => hintFor(n, hints),
          ),
          showPlaceholder: (_, n) => hintFor(n, hints).isNotEmpty,
        ),
        BulletedListBlockKeys.type: BulletedListBlockComponentBuilder(
          configuration: standardBlockComponentConfiguration.copyWith(
            placeholderText: (n) => hintFor(n, hints),
          ),
        ),
        TodoListBlockKeys.type: TodoListBlockComponentBuilder(
          configuration: standardBlockComponentConfiguration.copyWith(
            placeholderText: (n) => hintFor(n, hints),
          ),
        ),
      },
    };

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
                    if (template != null)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: LumSpace.sm),
                          child: Text(
                            template!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: LumText.footnote
                                .copyWith(color: lum.textSecondary),
                          ),
                        ),
                      )
                    else
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
                          LumCircleButton(
                            plain: true,
                            icon: PhosphorIcons.dotsThree(),
                            label: NotesStrings.noteOptions,
                            onPressed: openNoteMenu,
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
                  Column(children: [
                    if (firstAudio.value case final a?)
                      NotePlayerBar(
                        path: a.path,
                        durationMs: a.ms,
                        speed: a.speed,
                        markerSeconds: markerSeconds.value,
                      ),
                    Expanded(
                      child: AppFlowyEditor(
                        editorState: editorState,
                        editorStyle: editorStyle,
                        autoFocus: noteId == null && template == null,
                        header: titleField,
                        blockComponentBuilders: {
                          ...standardBlockComponentBuilderMap,
                          ...templateBuilders,
                          ImageBlockKeys.type: mediaBuilder,
                          audioNodeType: mediaBuilder,
                        },
                      ),
                    ),
                  ]),
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
