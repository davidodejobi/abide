import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_chapter.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';
import 'package:openbaptisthymnal/features/bible/providers/pending_verse_highlight_provider.dart';

/// Public chapter renderer. Used by the main reader and by either pane of the
/// split view. Verse interaction (select/long-press) is optional — pass nulls
/// to render in read-only mode (the secondary split pane).
///
/// Honours a one-shot [pendingVerseHighlightProvider]: if the active request
/// matches this view's edition+chapter, the verses in its range get a soft
/// glow on first build, then the request is cleared so it doesn't re-flash.
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
    final query = (editionId: editionId, ordinal: ordinal, chapter: chapter);
    final chapterAsync = ref.watch(bibleChapterProvider(query));
    final colorScheme = Theme.of(context).colorScheme;

    // Consume any pending highlight for this exact chapter. Reading the
    // notifier (not the value) keeps this widget from rebuilding when the
    // highlight is cleared.
    final pending = ref
        .read(pendingVerseHighlightProvider.notifier)
        .takeFor(editionId: editionId, ordinal: ordinal, chapter: chapter);

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
        padding: padding,
        highlightFrom: pending?.fromVerse,
        highlightTo: pending?.toVerse,
      ),
    );
  }
}

class _VerseList extends StatefulWidget {
  const _VerseList({
    required this.chapter,
    required this.textScale,
    required this.selected,
    required this.onTapVerse,
    required this.onLongPressVerse,
    required this.padding,
    required this.highlightFrom,
    required this.highlightTo,
  });

  final BibleChapter chapter;
  final double textScale;
  final Set<int> selected;
  final ValueChanged<int>? onTapVerse;
  final ValueChanged<int>? onLongPressVerse;
  final EdgeInsetsGeometry padding;
  final int? highlightFrom;
  final int? highlightTo;

  @override
  State<_VerseList> createState() => _VerseListState();
}

class _VerseListState extends State<_VerseList> {
  late final ScrollController _controller;
  bool _hasScrolledToHighlight = false;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    if (widget.highlightFrom != null) {
      // Scroll so the highlighted verse is roughly centered. We use a rough
      // 56px-per-verse estimate which is close enough for short chapters;
      // long chapters are scrolled to the proportional offset.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.hasClients) return;
        if (_hasScrolledToHighlight) return;
        _hasScrolledToHighlight = true;
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
