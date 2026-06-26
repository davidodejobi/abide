import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/features/bible/domain/highlight_palette.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_chapter.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';
import 'package:openbaptisthymnal/features/bible/providers/pending_verse_highlight_provider.dart';

/// Public chapter renderer. Used by the main reader and by either pane of the
/// split view. Verse interaction (select/long-press) is optional — pass nulls
/// to render in read-only mode (the secondary split pane).
///
/// Honours a one-shot [pendingVerseHighlightProvider]: if the active request
/// matches this view's edition+chapter, the verses in its range get a soft
/// glow on first mount and the view scrolls to them, then the request is
/// cleared after the first frame so a later rebuild won't re-trigger it.
class BibleChapterView extends ConsumerWidget {
  const BibleChapterView({
    super.key,
    required this.editionId,
    required this.bookCode,
    required this.chapter,
    required this.textScale,
    this.selected = const <int>{},
    this.onTapVerse,
    this.onLongPressVerse,
    this.backlinkVerses = const <int>{},
    this.onTapBacklink,
    this.highlights = const <int, BibleAnnotation>{},
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 120),
  });

  final String editionId;
  final String bookCode;
  final int chapter;
  final double textScale;
  final Set<int> selected;
  final ValueChanged<int>? onTapVerse;
  final ValueChanged<int>? onLongPressVerse;

  /// Verse numbers that have at least one linking tablet; each renders a small
  /// tappable indicator next to its number.
  final Set<int> backlinkVerses;
  final ValueChanged<int>? onTapBacklink;

  /// Verse number -> saved highlight annotation. Edition-independent.
  final Map<int, BibleAnnotation> highlights;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = (editionId: editionId, bookCode: bookCode, chapter: chapter);
    final chapterAsync = ref.watch(bibleChapterProvider(query));
    final colorScheme = Theme.of(context).colorScheme;

    // Read-only peek at any pending highlight. Clearing happens in the
    // stateful child's post-frame callback so we never mutate a provider
    // while the widget tree is building.
    final pending = ref.watch(pendingVerseHighlightProvider);
    final matches = pending != null &&
        pending.matches(
          editionId: editionId,
          bookCode: bookCode,
          chapter: chapter,
        );

    return chapterAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      ),
      error: (e, _) =>
          const Center(child: Text('Failed to load this chapter')),
      data: (data) => _VerseList(
        chapter: data,
        textScale: textScale,
        selected: selected,
        onTapVerse: onTapVerse,
        onLongPressVerse: onLongPressVerse,
        backlinkVerses: backlinkVerses,
        onTapBacklink: onTapBacklink,
        highlights: highlights,
        padding: padding,
        highlightFrom: matches ? pending.fromVerse : null,
        highlightTo: matches ? pending.toVerse : null,
      ),
    );
  }
}

class _VerseList extends ConsumerStatefulWidget {
  const _VerseList({
    required this.chapter,
    required this.textScale,
    required this.selected,
    required this.onTapVerse,
    required this.onLongPressVerse,
    required this.backlinkVerses,
    required this.onTapBacklink,
    required this.highlights,
    required this.padding,
    required this.highlightFrom,
    required this.highlightTo,
  });

  final BibleChapter chapter;
  final double textScale;
  final Set<int> selected;
  final ValueChanged<int>? onTapVerse;
  final ValueChanged<int>? onLongPressVerse;
  final Set<int> backlinkVerses;
  final ValueChanged<int>? onTapBacklink;
  final Map<int, BibleAnnotation> highlights;
  final EdgeInsetsGeometry padding;
  final int? highlightFrom;
  final int? highlightTo;

  @override
  ConsumerState<_VerseList> createState() => _VerseListState();
}

class _VerseListState extends ConsumerState<_VerseList> {
  late final ScrollController _controller;
  bool _hasConsumedHighlight = false;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    if (widget.highlightFrom != null) {
      // Scroll + clear after the first frame so we don't modify the provider
      // mid-build. The rough 64px-per-verse estimate is close enough for short
      // chapters; longer chapters land at the proportional offset.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_hasConsumedHighlight) return;
        _hasConsumedHighlight = true;
        if (_controller.hasClients) {
          final index = widget.highlightFrom! - 1;
          final estimated = (index * 64.0).clamp(
            0.0,
            _controller.position.maxScrollExtent,
          );
          _controller.animateTo(
            estimated,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          );
        }
        ref.read(pendingVerseHighlightProvider.notifier).clear();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hiFrom = widget.highlightFrom;
    final hiTo = widget.highlightTo;

    return ListView.builder(
      controller: _controller,
      // Keying on the chapter resets the scroll offset on every chapter change,
      // so the reader always starts at verse 1.
      key: ValueKey('${widget.chapter.book}.${widget.chapter.chapter}'),
      padding: widget.padding,
      itemCount: widget.chapter.verses.length,
      itemBuilder: (context, index) {
        final verse = widget.chapter.verses[index];
        final isSelected = widget.selected.contains(verse.number);
        final hasBacklink = widget.backlinkVerses.contains(verse.number);
        final highlightSwatch =
            HighlightColor.fromKey(widget.highlights[verse.number]?.color)
                ?.swatch;
        final isHighlighted = hiFrom != null &&
            verse.number >= hiFrom &&
            verse.number <= (hiTo ?? hiFrom);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTapVerse == null
              ? null
              : () => widget.onTapVerse!(verse.number),
          onLongPress: widget.onLongPressVerse == null
              ? null
              : () => widget.onLongPressVerse!(verse.number),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.14)
                  : isHighlighted
                      ? colorScheme.secondary.withValues(alpha: 0.18)
                      : highlightSwatch != null
                          ? highlightSwatch.withValues(alpha: 0.35)
                          : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamilyGeist,
                  fontSize: 16 * widget.textScale,
                  height: 1.5,
                  color: colorScheme.onSurface,
                ),
                children: [
                  TextSpan(
                    text: '${verse.number}  ',
                    style: TextStyle(
                      fontSize: 13 * widget.textScale,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (hasBacklink)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: widget.onTapBacklink == null
                            ? null
                            : () => widget.onTapBacklink!(verse.number),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.chat_bubble_outline,
                            size: 13 * widget.textScale,
                            color: colorScheme.secondary,
                          ),
                        ),
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
