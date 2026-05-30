import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/features/notes/providers/notes_providers.dart';

/// Create / edit a single note. Markdown is stored verbatim for now; rich
/// editing (Phase 1) will layer on top of the same persisted markdown.
@RoutePage()
class NoteEditorPage extends HookConsumerWidget {
  const NoteEditorPage({super.key, this.noteId});

  final String? noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = useTextEditingController();
    final bodyController = useTextEditingController();
    final currentId = useState<String?>(noteId);
    final createdAt = useRef<DateTime?>(null);
    final seeded = useRef(false);

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

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) save();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.router.maybePop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Save',
              onPressed: () async {
                await save();
                if (context.mounted) context.router.maybePop();
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: titleController,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Title',
                    border: InputBorder.none,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: bodyController,
                    expands: true,
                    maxLines: null,
                    textAlignVertical: TextAlignVertical.top,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(
                      fontFamily: 'EBGaramond',
                      fontSize: 18,
                      height: 1.5,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Start writing…',
                      border: InputBorder.none,
                    ),
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
