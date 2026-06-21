import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_chapter.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';

/// Public chapter renderer. Used by the main reader and by either pane of the
/// split view. Verse interaction (select/long-press) is optional — pass nulls
/// to render in read-only mode (the secondary split pane).
class BibleChapterView extends ConsumerWidget {
  const BibleChapterView({
    super.key,
    required this.editionId,
    required this.ordinal,
    required this.chapter,
    required this.textScale,
    this.selected = const <int>{},
    this.onTapVerse,
    this.onLongPressVerse,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 120),
  });

  final String editionId;
  final int ordinal;
  final int chapter;
  final double textScale;
  final Set<int> selected;
  final ValueChanged<int>? onTapVerse;
  final ValueChanged<int>? onLongPressVerse;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query =
        (editionId: editionId, ordinal: ordinal, chapter: chapter);
    final chapterAsync = ref.watch(bibleChapterProvider(query));
    final colorScheme = Theme.of(context).colorScheme;

    return chapterAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      ),
      error: (e, _) => Center(child: Text('Failed to load this chapter')),
      data: (data) => _VerseList(
        chapter: data,
        textScale: textScale,
        selected: selected,
        onTapVerse: onTapVerse,
        onLongPressVerse: onLongPressVerse,
        padding: padding,
      ),
    );
  }
}

class _VerseList extends StatelessWidget {
  const _VerseList({
    required this.chapter,
    required this.textScale,
    required this.selected,
    required this.onTapVerse,
    required this.onLongPressVerse,
    required this.padding,
  });

  final BibleChapter chapter;
  final double textScale;
  final Set<int> selected;
  final ValueChanged<int>? onTapVerse;
  final ValueChanged<int>? onLongPressVerse;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.builder(
      // Keying on the chapter resets the scroll offset on every chapter change,
      // so the reader always starts at verse 1.
      key: ValueKey('${chapter.book}.${chapter.chapter}'),
      padding: padding,
      itemCount: chapter.verses.length,
      itemBuilder: (context, index) {
        final verse = chapter.verses[index];
        final isSelected = selected.contains(verse.number);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTapVerse == null ? null : () => onTapVerse!(verse.number),
          onLongPress: onLongPressVerse == null
              ? null
              : () => onLongPressVerse!(verse.number),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamilyGeist,
                  fontSize: 16 * textScale,
                  height: 1.5,
                  color: colorScheme.onSurface,
                ),
                children: [
                  TextSpan(
                    text: '${verse.number}  ',
                    style: TextStyle(
                      fontSize: 13 * textScale,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: verse.text),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
