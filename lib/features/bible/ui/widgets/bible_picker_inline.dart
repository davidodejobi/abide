import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';
import 'package:openbaptisthymnal/features/bible/ui/widgets/book_picker_sheet.dart';
import 'package:openbaptisthymnal/features/bible/ui/widgets/chapter_picker_sheet.dart';

/// Inline edition + book + chapter picker for the Bible split-view secondary
/// pane. Renders a compact form; on Pick the parent gets the full triple.
class BiblePickerInline extends ConsumerWidget {
  const BiblePickerInline({
    super.key,
    required this.editionId,
    required this.onPicked,
    required this.onEditionChanged,
  });

  final String editionId;
  final void Function(String editionId, String bookCode, int chapter) onPicked;
  final ValueChanged<String> onEditionChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editions = ref.watch(bibleEditionsProvider);
    final manifestAsync = ref.watch(bibleManifestProvider(editionId));
    final ink = Theme.of(context).colorScheme.onSurface;

    Future<void> openPickers(BibleManifest manifest) async {
      final ordinal = await showBookPicker(
        context,
        manifest: manifest,
        currentOrdinal: manifest.books.first.ordinal,
      );
      if (ordinal == null || !context.mounted) return;
      final book = manifest.books.firstWhere((b) => b.ordinal == ordinal);
      final chapter = await showChapterPicker(
        context,
        bookName: book.name,
        chapterCount: book.chapterCount,
        currentChapter: 1,
      );
      if (chapter == null) return;
      onPicked(editionId, book.code, chapter);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pick a chapter',
            style: AppTextStyles.titleMedium
                .copyWith(fontWeight: FontWeight.w600, color: ink),
          ),
          const SizedBox(height: 12),
          Text(
            'Edition',
            style: AppTextStyles.bodySmall.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              color: ink.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in editions)
                ChoiceChip(
                  selected: e.id == editionId,
                  label: Text(e.displayName),
                  onSelected: (_) => onEditionChanged(e.id),
                ),
            ],
          ),
          const SizedBox(height: 20),
          manifestAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Text('Could not load this edition: $e'),
            data: (manifest) => FilledButton.icon(
              onPressed: () => openPickers(manifest),
              icon: const Icon(Icons.menu_book_rounded),
              label: const Text('Choose book and chapter'),
            ),
          ),
        ],
      ),
    );
  }
}
