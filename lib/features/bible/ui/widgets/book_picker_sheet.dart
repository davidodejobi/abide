import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/features/bible/domain/book_codes.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';
import 'package:openbaptisthymnal/features/bible/ui/bible_strings.dart';

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
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Semantics(
              header: true,
              child: Text(BibleStrings.books,
                  style:
                      LumText.title2.copyWith(color: context.lum.textPrimary)),
            ),
          ),
        ),
        _testamentHeader(context, BibleStrings.oldTestament),
        _bookGrid(context, ot),
        _testamentHeader(context, BibleStrings.newTestament),
        _bookGrid(context, nt),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _testamentHeader(BuildContext context, String label) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Text(label,
            style: LumText.roadLabelCaps11
                .copyWith(color: context.lum.textSecondary)),
      ),
    );
  }

  Widget _bookGrid(BuildContext context, List<BibleBookInfo> books) {
    final c = context.lum;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          mainAxisExtent: 56,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final book = books[index];
            final selected = book.ordinal == currentOrdinal;
            return Semantics(
              button: true,
              selected: selected,
              label: book.name,
              excludeSemantics: true,
              onTap: () => Navigator.of(context).pop(book.ordinal),
              child: Material(
                color: selected ? c.bgPrimary : c.bgSurface,
                borderRadius: BorderRadius.circular(LumRadius.md),
                child: InkWell(
                  borderRadius: BorderRadius.circular(LumRadius.md),
                  onTap: () => Navigator.of(context).pop(book.ordinal),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        book.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: LumText.subheadlineEmphasized.copyWith(
                          color: selected ? c.textOnPrimary : c.textPrimary,
                        ),
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
