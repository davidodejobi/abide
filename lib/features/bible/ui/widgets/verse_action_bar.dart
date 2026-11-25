import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/database_provider.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/widgets/lum_circle_button.dart';
import 'package:openbaptisthymnal/core/widgets/lum_glass_bar.dart';
import 'package:openbaptisthymnal/features/bible/domain/highlight_palette.dart';
import 'package:openbaptisthymnal/features/bible/domain/verse_reference_format.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';
import 'package:openbaptisthymnal/features/bible/providers/verse_highlights_provider.dart';
import 'package:openbaptisthymnal/features/bible/ui/bible_strings.dart';
import 'package:openbaptisthymnal/features/bible/ui/widgets/highlight_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Glass verse actions (Figma 03): five highlight swatches, add note, share.
/// Replaces the chapter nav while verses are selected. Tapping the swatch that
/// already colours every selected verse removes the highlight.
class VerseActionBar extends ConsumerWidget {
  const VerseActionBar({
    super.key,
    required this.editionId,
    required this.book,
    required this.chapter,
    required this.selected,
    required this.onClear,
  });

  final String editionId;
  final BibleBookInfo book;
  final int chapter;
  final Set<int> selected;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lum;
    final query = (editionId: editionId, bookCode: book.code, chapter: chapter);
    final chapterData = ref.watch(bibleChapterProvider(query)).valueOrNull;
    final highlights = ref
            .watch(verseHighlightsProvider(
              (bookCode: book.code, chapter: chapter),
            ))
            .valueOrNull ??
        const <int, BibleAnnotation>{};

    // The one colour shared by every selected verse, if there is one.
    final keys = {for (final v in selected) highlights[v]?.color};
    final sharedKey = keys.length == 1 ? keys.first : null;

    String verseRef(int v) => '${book.code}.$chapter.$v';
    int anchorVerse() => selected.reduce((a, b) => a < b ? a : b);

    Future<void> applyColor(HighlightColor h) async {
      final dao = ref.read(bibleAnnotationsDaoProvider);
      for (final v in selected) {
        if (sharedKey == h.key) {
          await dao.removeHighlight(verseRef(v));
        } else {
          await dao.setHighlight(verseRef(v), h.key);
        }
      }
      onClear();
    }

    // Tie the verse(s) to a new tablet: default-highlight them yellow (an
    // explicit verse->note link deserves a visible mark) and open the editor
    // pre-filled with the bible link, which note_links picks up on save so the
    // backlink indicator surfaces this tablet.
    Future<void> addNote() async {
      if (selected.isEmpty) return;
      final dao = ref.read(bibleAnnotationsDaoProvider);
      final anchor = anchorVerse();
      for (final v in selected) {
        await dao.setHighlight(verseRef(v), HighlightColor.yellow.key);
      }
      if (!context.mounted) return;
      onClear();
      context.router.push(
        TabletEditorRoute(initialMarkdown: '[[bible:${verseRef(anchor)}]]\n\n'),
      );
    }

    void share() {
      if (chapterData == null) return;
      final picked = chapterData.verses
          .where((v) => selected.contains(v.number))
          .toList()
        ..sort((a, b) => a.number.compareTo(b.number));
      if (picked.isEmpty) return;
      final verses = [
        for (final v in picked) (number: v.number, text: v.text),
      ];
      final reference = '${book.name} ${formatVerseRange(chapter, selected)}';
      context.router.push(
        ScriptureShareCardRoute(reference: reference, verses: verses),
      );
    }

    return Semantics(
      container: true,
      label: BibleStrings.selected(selected.length),
      child: LumGlassBar(
        padding: const EdgeInsets.symmetric(horizontal: LumSpace.xs),
        // Scrolls sideways rather than overflowing on narrow or zoomed screens.
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
                minWidth: MediaQuery.sizeOf(context).width -
                    2 * LumSpace.md -
                    2 * LumSpace.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                LumCircleButton(
                  plain: true,
                  icon: PhosphorIcons.x(),
                  label: BibleStrings.clearSelection,
                  onPressed: onClear,
                ),
                for (final h in HighlightColor.values)
                  _Swatch(
                    color: highlightColorFor(c, h),
                    label: '${BibleStrings.highlightPrefix} ${h.key}',
                    checked: sharedKey == h.key,
                    onTap: () => applyColor(h),
                  ),
                LumCircleButton(
                  plain: true,
                  icon: PhosphorIcons.pencilSimple(),
                  label: BibleStrings.addNote,
                  onPressed: addNote,
                ),
                LumCircleButton(
                  plain: true,
                  icon: PhosphorIcons.export(),
                  label: BibleStrings.share,
                  onPressed: chapterData == null ? null : share,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.label,
    required this.checked,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Semantics(
      button: true,
      selected: checked,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: LumSize.touchTarget,
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: c.borderStrong),
              ),
              child: checked
                  ? Icon(Icons.check_rounded, size: 20, color: c.textPrimary)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
