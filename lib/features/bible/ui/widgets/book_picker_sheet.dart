import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/features/bible/domain/book_codes.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';

/// Lets the reader pick a book, grouped into Old and New Testament. Returns the
/// chosen book's 1-based ordinal via [Navigator.pop], or null if dismissed.
Future<int?> showBookPicker(
  BuildContext context, {
  required BibleManifest manifest,
  required int currentOrdinal,
}) {
  return showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.9,
    ),
    builder: (context) => _BookPickerSheet(
      manifest: manifest,
      currentOrdinal: currentOrdinal,
    ),
  );
}

class _BookPickerSheet extends StatelessWidget {
  const _BookPickerSheet({
    required this.manifest,
    required this.currentOrdinal,
  });

  final BibleManifest manifest;
  final int currentOrdinal;

  @override
  Widget build(BuildContext context) {
    final ot = manifest.books
        .where((b) => isOldTestament(b.ordinal))
        .toList(growable: false);
    final nt = manifest.books
        .where((b) => !isOldTestament(b.ordinal))
        .toList(growable: false);

    return CustomScrollView(
      slivers: [
        _header(context),
        _testamentHeader(context, 'Old Testament'),
        _bookGrid(context, ot),
        _testamentHeader(context, 'New Testament'),
        _bookGrid(context, nt),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _header(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Text(
          'Books',
          style: AppTextStyles.headlineSmall
              .copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _testamentHeader(BuildContext context, String label) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: Theme.of(context).hintColor,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _bookGrid(BuildContext context, List<BibleBookInfo> books) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          mainAxisExtent: 48,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final book = books[index];
            final selected = book.ordinal == currentOrdinal;
            return Material(
              color: selected
                  ? colorScheme.primary.withValues(alpha: 0.12)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Navigator.of(context).pop(book.ordinal),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      book.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected ? colorScheme.primary : null,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          childCount: books.length,
        ),
      ),
    );
  }
}
