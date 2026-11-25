import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/features/bible/domain/highlight_palette.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_chapter.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';
import 'package:openbaptisthymnal/features/bible/providers/pending_verse_highlight_provider.dart';
import 'package:openbaptisthymnal/features/bible/ui/bible_strings.dart';
import 'package:openbaptisthymnal/features/bible/ui/widgets/highlight_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Public chapter renderer. Used by the main reader and by either pane of the
/// split view. Verse interaction (select/long-press) is optional: pass nulls
/// to render in read-only mode (the secondary split pane).
///
/// Scripture is always set in the reading style on the calm page colour, never
/// over art. [header] scrolls with the text (the big chapter title).
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
    this.padding = const EdgeInsets.fromLTRB(
        LumSize.screenGutter - 4, LumSpace.sm, LumSize.screenGutter - 4, 200),
    this.header,
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
  final Widget? header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = (editionId: editionId, bookCode: bookCode, chapter: chapter);
    final chapterAsync = ref.watch(bibleChapterProvider(query));
    final c = context.lum;

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
        child: CircularProgressIndicator(color: c.textSecondary),
      ),
      error: (e, _) => Center(
        child: Text(BibleStrings.chapterLoadError,
            style: LumText.body.copyWith(color: c.textSecondary)),
      ),
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
        header: header,
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
    required this.header,
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
  final Widget? header;

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
            duration: LumMotion.base,
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
    final c = context.lum;
    final hiFrom = widget.highlightFrom;
    final hiTo = widget.highlightTo;
    final hasHeader = widget.header != null;
    final scripture = LumText.readingScripture.copyWith(
      fontSize: LumText.readingScripture.fontSize! * widget.textScale,
      color: c.textPrimary,
    );
    final number = LumText.readingVerseNumber.copyWith(
      fontSize: LumText.readingVerseNumber.fontSize! * widget.textScale,
      color: c.textSecondary,
    );

    return ListView.builder(
      controller: _controller,
      key: ValueKey('${widget.chapter.book}.${widget.chapter.chapter}'),
      padding: widget.padding,
      itemCount: widget.chapter.verses.length + (hasHeader ? 1 : 0),
      itemBuilder: (context, index) {
        if (hasHeader && index == 0) return widget.header!;
        final verse = widget.chapter.verses[index - (hasHeader ? 1 : 0)];
        final isSelected = widget.selected.contains(verse.number);
        final hasBacklink = widget.backlinkVerses.contains(verse.number);
        final marked =
            HighlightColor.fromKey(widget.highlights[verse.number]?.color);
        final isFlashing = hiFrom != null &&
            verse.number >= hiFrom &&
            verse.number <= (hiTo ?? hiFrom);
        final fill = isSelected
            ? c.bgAccentContainer
            : isFlashing
                ? c.bgAccentContainer
                : marked != null
                    ? highlightColorFor(c, marked)
                    : Colors.transparent;
        final text = Text.rich(
          TextSpan(
            style: scripture,
            children: [
              TextSpan(text: '${verse.number} ', style: number),
              if (hasBacklink)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Semantics(
                    button: true,
                    label: BibleStrings.backlinks,
                    excludeSemantics: true,
                    onTap: widget.onTapBacklink == null
                        ? null
                        : () => widget.onTapBacklink!(verse.number),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onTapBacklink == null
                          ? null
                          : () => widget.onTapBacklink!(verse.number),
                      child: Container(
                        width: LumSize.touchTarget,
                        height: LumSize.touchTarget,
                        alignment: Alignment.center,
                        child: Icon(
                          PhosphorIcons.chatTeardropText(),
                          size: 14 * widget.textScale,
                          color: c.iconAccent,
                        ),
                      ),
                    ),
                  ),
                ),
              TextSpan(text: verse.text),
            ],
          ),
        );
        return Semantics(
          selected: isSelected,
          onTap: widget.onTapVerse == null
              ? null
              : () => widget.onTapVerse!(verse.number),
          onLongPress: widget.onLongPressVerse == null
              ? null
              : () => widget.onLongPressVerse!(verse.number),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTapVerse == null
                ? null
                : () => widget.onTapVerse!(verse.number),
            onLongPress: widget.onLongPressVerse == null
                ? null
                : () => widget.onLongPressVerse!(verse.number),
            child: AnimatedContainer(
              duration: LumMotion.fast,
              margin: const EdgeInsets.only(bottom: LumSpace.xs),
              padding: const EdgeInsets.symmetric(
                  horizontal: LumSpace.sm, vertical: LumSpace.xs),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(LumRadius.md),
              ),
              child: text,
            ),
          ),
        );
      },
    );
  }
}
