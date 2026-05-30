import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';

/// Shows a grid of chapter numbers for [bookName]. Returns the chosen 1-based
/// chapter via [Navigator.pop], or null if dismissed.
Future<int?> showChapterPicker(
  BuildContext context, {
  required String bookName,
  required int chapterCount,
  required int currentChapter,
}) {
  return showModalBottomSheet<int>(
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
    final colorScheme = Theme.of(context).colorScheme;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              bookName,
              style: AppTextStyles.headlineSmall
                  .copyWith(fontWeight: FontWeight.w600),
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
                return Material(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.of(context).pop(chapter),
                    child: Center(
                      child: Text(
                        '$chapter',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? colorScheme.onPrimary : null,
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
