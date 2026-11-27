import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';

/// Shows a grid of chapter numbers for [bookName]. Returns the chosen 1-based
/// chapter via [Navigator.pop], or null if dismissed.
Future<int?> showChapterPicker(
  BuildContext context, {
  required String bookName,
  required int chapterCount,
  required int currentChapter,
}) {
  return showModalBottomSheet<int>(
    useRootNavigator: true,
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.9,
    ),
    builder: (context) => _ChapterPickerSheet(
      bookName: bookName,
      chapterCount: chapterCount,
      currentChapter: currentChapter,
    ),
  );
}

class _ChapterPickerSheet extends StatelessWidget {
  const _ChapterPickerSheet({
    required this.bookName,
    required this.chapterCount,
    required this.currentChapter,
  });

  final String bookName;
  final int chapterCount;
  final int currentChapter;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Semantics(
              header: true,
              child: Text(bookName,
                  style: LumText.title2.copyWith(color: c.textPrimary)),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 64,
              mainAxisExtent: 56,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final chapter = index + 1;
                final selected = chapter == currentChapter;
                return Semantics(
                  button: true,
                  selected: selected,
                  label: '$chapter',
                  excludeSemantics: true,
                  onTap: () => Navigator.of(context).pop(chapter),
                  child: Material(
                    color: selected ? c.bgPrimary : c.bgSurface,
                    borderRadius: BorderRadius.circular(LumRadius.md),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(LumRadius.md),
                      onTap: () => Navigator.of(context).pop(chapter),
                      child: Center(
                        child: Text(
                          '$chapter',
                          style: LumText.bodyEmphasized.copyWith(
                              color:
                                  selected ? c.textOnPrimary : c.textPrimary),
                        ),
                      ),
                    ),
                  ),
                );
              },
              childCount: chapterCount,
            ),
          ),
        ),
      ],
    );
  }
}
