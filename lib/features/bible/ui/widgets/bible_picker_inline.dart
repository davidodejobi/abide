import 'package:material_ui/material_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/widgets/lum_button.dart';
import 'package:openbaptisthymnal/core/widgets/lum_chip.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';
import 'package:openbaptisthymnal/features/bible/ui/bible_strings.dart';
import 'package:openbaptisthymnal/features/bible/ui/widgets/book_picker_sheet.dart';
import 'package:openbaptisthymnal/features/bible/ui/widgets/chapter_picker_sheet.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
    final c = context.lum;
    final editions = ref.watch(bibleEditionsProvider);
    final manifestAsync = ref.watch(bibleManifestProvider(editionId));

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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(LumSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(BibleStrings.pickChapter,
                style: LumText.title3.copyWith(color: c.textPrimary)),
          ),
          const SizedBox(height: LumSpace.md),
          Text(BibleStrings.edition,
              style: LumText.roadLabelCaps11.copyWith(color: c.textSecondary)),
          const SizedBox(height: LumSpace.sm),
          Wrap(
            spacing: LumSpace.sm,
            runSpacing: LumSpace.sm,
            children: [
              for (final e in editions)
                LumChip(
                  selected: e.id == editionId,
                  label: BibleStrings.languageAndVersion(e),
                  onTap: () => onEditionChanged(e.id),
                ),
            ],
          ),
          const SizedBox(height: LumSpace.xl),
          manifestAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(BibleStrings.loadError,
                style: LumText.body.copyWith(color: c.textSecondary)),
            data: (manifest) => LumButton(
              onPressed: () => openPickers(manifest),
              icon: Icon(PhosphorIcons.bookOpenText()),
              label: BibleStrings.chooseBookAndChapter,
            ),
          ),
        ],
      ),
    );
  }
}
