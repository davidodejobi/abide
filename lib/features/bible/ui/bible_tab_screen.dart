import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/providers/bottom_nav_provider.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/note_links_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/database_provider.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/core/theme/font_scale_provider.dart';
import 'package:openbaptisthymnal/core/widgets/split_orientation_toggle.dart';
import 'package:openbaptisthymnal/core/widgets/split_pane.dart';
import 'package:openbaptisthymnal/features/bible/domain/highlight_palette.dart';
import 'package:openbaptisthymnal/features/bible/domain/verse_reference_format.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';
import 'package:openbaptisthymnal/features/bible/providers/verse_backlinks_provider.dart';
import 'package:openbaptisthymnal/features/bible/providers/verse_highlights_provider.dart';
import 'package:openbaptisthymnal/features/bible/ui/widgets/bible_chapter_view.dart';
import 'package:openbaptisthymnal/features/bible/ui/widgets/bible_picker_inline.dart';
import 'package:openbaptisthymnal/features/bible/ui/widgets/book_picker_sheet.dart';
import 'package:openbaptisthymnal/features/bible/ui/widgets/chapter_picker_sheet.dart';

/// Ephemeral split state for the Bible tab: the user opens a second pane,
/// flips between vertical and horizontal layouts, and picks a different
/// edition/book/chapter for the secondary pane.
class _BibleSplitState {
  const _BibleSplitState({
    required this.isOpen,
    required this.orientation,
    required this.secondaryEditionId,
    required this.secondaryBookCode,
    required this.secondaryChapter,
  });

  final bool isOpen;
  final SplitOrientation orientation;
  final String? secondaryEditionId;
  final String? secondaryBookCode;
  final int? secondaryChapter;

  bool get hasSecondaryChapter =>
      secondaryEditionId != null &&
      secondaryBookCode != null &&
      secondaryChapter != null;

  static const initial = _BibleSplitState(
    isOpen: false,
    orientation: SplitOrientation.vertical,
    secondaryEditionId: null,
    secondaryBookCode: null,
    secondaryChapter: null,
  );

  _BibleSplitState copyWith({
    bool? isOpen,
    SplitOrientation? orientation,
    String? secondaryEditionId,
    String? secondaryBookCode,
    int? secondaryChapter,
    bool clearSecondaryChapter = false,
  }) =>
      _BibleSplitState(
        isOpen: isOpen ?? this.isOpen,
        orientation: orientation ?? this.orientation,
        secondaryEditionId: secondaryEditionId ?? this.secondaryEditionId,
        secondaryBookCode: clearSecondaryChapter
            ? null
            : (secondaryBookCode ?? this.secondaryBookCode),
        secondaryChapter: clearSecondaryChapter
            ? null
            : (secondaryChapter ?? this.secondaryChapter),
      );
}

/// The Bible reading tab: a header that opens book/chapter pickers and an
/// edition switch, with the current chapter rendered below. The reading
/// position is persisted, so the tab reopens where the reader left off.
///
/// Long-pressing a verse starts a selection; further taps add or remove verses.
/// While a selection is active the header becomes a share bar. Verse text size
/// follows the app-wide [fontScaleProvider] set in Settings.
@RoutePage()
class BibleTabScreen extends HookConsumerWidget {
  const BibleTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useAutomaticKeepAlive();

    final position = ref.watch(bibleReadingPositionProvider);
    final manifestAsync = ref.watch(bibleManifestProvider(position.editionId));
    final textScale = ref.watch(fontScaleProvider).scale;
    final colorScheme = Theme.of(context).colorScheme;
    final editions = ref.watch(bibleEditionsProvider);
    final split = useState(_BibleSplitState.initial);

    // Selected verse numbers for the chapter currently in view. Reset whenever
    // the reader moves to a different edition, book, or chapter.
    final selected = useState<Set<int>>(<int>{});
    // Bottom chrome (chapter nav + the app's glass tab bar) auto-hides while
    // reading down, returns on scroll up and on every chapter change.
    final navVisible = ref.watch(bottomNavVisibleProvider);
    useEffect(() {
      selected.value = <int>{};
      // Deferred: provider writes are not allowed during build.
      Future.microtask(
        () => ref.read(bottomNavVisibleProvider.notifier).state = true,
      );
      return null;
    }, [position.editionId, position.bookCode, position.chapter]);

    void toggleVerse(int number) {
      final next = {...selected.value};
      if (!next.remove(number)) next.add(number);
      selected.value = next;
    }

    void onTapVerse(int number) {
      if (selected.value.isEmpty) return; // normal reading when not selecting
      toggleVerse(number);
    }

    void onLongPressVerse(int number) {
      HapticFeedback.selectionClick();
      if (!selected.value.contains(number)) {
        selected.value = {...selected.value, number};
      }
    }

    String otherEdition(String current) {
      final ids = editions.map((e) => e.id).toList();
      if (ids.length < 2) return current;
      final i = ids.indexOf(current);
      return i < 0 || i + 1 >= ids.length ? ids.first : ids[i + 1];
    }

    void openSplit() {
      // Auto-bilingual: drop the same book/chapter into the secondary pane in
      // the next available edition so a bilingual read is one tap away.
      final secondaryEdition = otherEdition(position.editionId);
      split.value = _BibleSplitState(
        isOpen: true,
        orientation: SplitOrientation.vertical,
        secondaryEditionId: secondaryEdition,
        secondaryBookCode: position.bookCode,
        secondaryChapter: position.chapter,
      );
    }

    void closeSplit() {
      split.value = _BibleSplitState.initial;
    }

    void clearSecondaryChapter() {
      split.value = split.value.copyWith(clearSecondaryChapter: true);
    }

    void onSecondaryPicked(String editionId, String bookCode, int chapter) {
      split.value = split.value.copyWith(
        secondaryEditionId: editionId,
        secondaryBookCode: bookCode,
        secondaryChapter: chapter,
      );
    }

    void onSecondaryEditionChanged(String editionId) {
      split.value = split.value.copyWith(secondaryEditionId: editionId);
    }

    void swapPanes() {
      final s = split.value;
      if (!s.hasSecondaryChapter) return;
      final oldPrimary = position;
      ref.read(bibleReadingPositionProvider.notifier)
        ..setEdition(s.secondaryEditionId!)
        ..openChapter(s.secondaryBookCode!, s.secondaryChapter!);
      split.value = s.copyWith(
        secondaryEditionId: oldPrimary.editionId,
        secondaryBookCode: oldPrimary.bookCode,
        secondaryChapter: oldPrimary.chapter,
      );
    }

    return manifestAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      ),
      error: (e, _) => _ErrorView(
        message: 'Failed to load this edition',
        onRetry: () =>
            ref.invalidate(bibleManifestProvider(position.editionId)),
      ),
      data: (manifest) {
        final book = manifest.books.firstWhere(
          (b) => b.code == position.bookCode,
          orElse: () => manifest.books.first,
        );

        final backlinks = ref
                .watch(verseBacklinksProvider(
                  (bookCode: book.code, chapter: position.chapter),
                ))
                .valueOrNull ??
            const <int, List<BibleBacklink>>{};

        final highlights = ref
                .watch(verseHighlightsProvider(
                  (bookCode: book.code, chapter: position.chapter),
                ))
                .valueOrNull ??
            const <int, BibleAnnotation>{};

        void openBacklinks(int verse) {
          final items = backlinks[verse];
          if (items == null || items.isEmpty) return;
          showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            builder: (_) => _BacklinksSheet(
              reference: '${book.name} ${position.chapter}:$verse',
              items: items,
            ),
          );
        }

        final books = manifest.books;
        final bookIndex = books.indexWhere((b) => b.ordinal == book.ordinal);

        void goPrev() {
          if (position.chapter > 1) {
            ref
                .read(bibleReadingPositionProvider.notifier)
                .openChapter(book.code, position.chapter - 1);
          } else if (bookIndex > 0) {
            final prev = books[bookIndex - 1];
            ref
                .read(bibleReadingPositionProvider.notifier)
                .openChapter(prev.code, prev.chapterCount);
          }
        }

        void goNext() {
          if (position.chapter < book.chapterCount) {
            ref
                .read(bibleReadingPositionProvider.notifier)
                .openChapter(book.code, position.chapter + 1);
          } else if (bookIndex < books.length - 1) {
            final next = books[bookIndex + 1];
            ref
                .read(bibleReadingPositionProvider.notifier)
                .openChapter(next.code, 1);
          }
        }

        final hasPrev = position.chapter > 1 || bookIndex > 0;
        final hasNext = position.chapter < book.chapterCount ||
            bookIndex < books.length - 1;

        final primaryView = BibleChapterView(
          editionId: position.editionId,
          bookCode: book.code,
          chapter: position.chapter,
          textScale: textScale,
          selected: selected.value,
          onTapVerse: onTapVerse,
          onLongPressVerse: onLongPressVerse,
          backlinkVerses: backlinks.keys.toSet(),
          onTapBacklink: openBacklinks,
          highlights: highlights,
          onPrev: hasPrev ? goPrev : null,
          onNext: hasNext ? goNext : null,
          hasPrev: hasPrev,
          hasNext: hasNext,
          bookName: book.name,
        );

        // Flat chapter list across the whole edition so a PageView can swipe
        // continuously through chapters and across book boundaries.
        final chapterRefs = [
          for (final b in books)
            for (var c = 1; c <= b.chapterCount; c++)
              (bookCode: b.code, chapter: c),
        ];
        var currentIndex = position.chapter - 1;
        for (var i = 0; i < bookIndex; i++) {
          currentIndex += books[i].chapterCount;
        }

        Widget body;
        if (!split.value.isOpen) {
          body = Column(
            children: [
              if (selected.value.isEmpty)
                _ReaderHeader(
                  manifest: manifest,
                  book: book,
                  onSplit: openSplit,
                  splitActive: false,
                )
              else
                _SelectionBar(
                  editionId: position.editionId,
                  book: book,
                  chapter: position.chapter,
                  selected: selected.value,
                  onClear: () => selected.value = <int>{},
                ),
              Expanded(
                child: NotificationListener<UserScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.axis != Axis.vertical) return false;
                    if (n.direction == ScrollDirection.reverse) {
                      ref.read(bottomNavVisibleProvider.notifier).state =
                          false;
                    } else if (n.direction == ScrollDirection.forward) {
                      ref.read(bottomNavVisibleProvider.notifier).state = true;
                    }
                    return false;
                  },
                  child: _ChapterPager(
                    key: ValueKey(position.editionId),
                    index: currentIndex,
                    itemCount: chapterRefs.length,
                    canSwipe: selected.value.isEmpty,
                    onIndexChanged: (i) {
                      HapticFeedback.selectionClick();
                      final target = chapterRefs[i];
                      ref
                          .read(bibleReadingPositionProvider.notifier)
                          .openChapter(target.bookCode, target.chapter);
                    },
                    itemBuilder: (context, i) {
                      if (i == currentIndex) return primaryView;
                      final target = chapterRefs[i];
                      return BibleChapterView(
                        editionId: position.editionId,
                        bookCode: target.bookCode,
                        chapter: target.chapter,
                        textScale: textScale,
                      );
                    },
                  ),
                ),
              ),
              ClipRect(
                child: AnimatedAlign(
                  alignment: Alignment.topCenter,
                  heightFactor: navVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: _ChapterNav(
                      manifest: manifest,
                      book: book,
                      chapter: position.chapter),
                ),
              ),
            ],
          );
        } else {
          body = Column(
            children: [
              _SplitHeader(
                orientation: split.value.orientation,
                onOrientationChanged: (o) =>
                    split.value = split.value.copyWith(orientation: o),
                onClose: closeSplit,
                primaryReference: '${book.name} ${position.chapter}',
                onPickPrimary: () => _pickPrimaryReference(
                  context,
                  ref,
                  manifest: manifest,
                  book: book,
                  currentChapter: position.chapter,
                ),
                onSwap: split.value.hasSecondaryChapter ? swapPanes : null,
              ),
              Expanded(
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity == null) return;
                    if (details.primaryVelocity! < -300 && hasNext) {
                      goNext();
                    } else if (details.primaryVelocity! > 300 && hasPrev) {
                      goPrev();
                    }
                  },
                  child: SplitPane(
                    orientation: split.value.orientation,
                    primary: primaryView,
                    secondary: _SecondaryBiblePane(
                      state: split.value,
                      textScale: textScale,
                      onPicked: onSecondaryPicked,
                      onEditionChanged: onSecondaryEditionChanged,
                      onChange: clearSecondaryChapter,
                    ),
                  ),
                ),
              ),
              _ChapterNav(
                  manifest: manifest, book: book, chapter: position.chapter),
            ],
          );
        }
        return body;
      },
    );
  }
}

/// Book -> chapter picker flow for the primary reading position, shared by
/// the reader header and the split header.
Future<void> _pickPrimaryReference(
  BuildContext context,
  WidgetRef ref, {
  required BibleManifest manifest,
  required BibleBookInfo book,
  required int currentChapter,
}) async {
  final ordinal = await showBookPicker(
    context,
    manifest: manifest,
    currentOrdinal: book.ordinal,
  );
  if (ordinal == null || !context.mounted) return;
  final picked = manifest.books.firstWhere((b) => b.ordinal == ordinal);
  final chapter = await showChapterPicker(
    context,
    bookName: picked.name,
    chapterCount: picked.chapterCount,
    currentChapter: ordinal == book.ordinal ? currentChapter : 1,
  );
  if (chapter == null) return;
  ref
      .read(bibleReadingPositionProvider.notifier)
      .openChapter(picked.code, chapter);
}

/// Swipeable chapter reader: a [PageView] over every chapter in the edition,
/// so the next/previous chapter slides in under the finger like any reading
/// app. Prev/Next buttons and pickers update the reading position instead;
/// the effect below re-syncs the controller (animating for neighbours,
/// jumping for far navigations like the book picker).
class _ChapterPager extends HookWidget {
  const _ChapterPager({
    super.key,
    required this.index,
    required this.itemCount,
    required this.canSwipe,
    required this.onIndexChanged,
    required this.itemBuilder,
  });

  final int index;
  final int itemCount;
  final bool canSwipe;
  final ValueChanged<int> onIndexChanged;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    final controller = usePageController(initialPage: index);

    useEffect(() {
      if (!controller.hasClients) return null;
      final page = controller.page?.round();
      if (page == null || page == index) return null;
      if ((page - index).abs() == 1) {
        controller.animateToPage(
          index,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        controller.jumpToPage(index);
      }
      return null;
    }, [index]);

    return PageView.builder(
      controller: controller,
      physics: canSwipe ? null : const NeverScrollableScrollPhysics(),
      onPageChanged: onIndexChanged,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

/// Book + chapter selector and an edition switch.
class _ReaderHeader extends ConsumerWidget {
  const _ReaderHeader({
    required this.manifest,
    required this.book,
    required this.onSplit,
    required this.splitActive,
  });

  final BibleManifest manifest;
  final BibleBookInfo book;
  final VoidCallback onSplit;
  final bool splitActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(bibleReadingPositionProvider);
    final editions = ref.watch(bibleEditionsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    Future<void> pickReference() => _pickPrimaryReference(
          context,
          ref,
          manifest: manifest,
          book: book,
          currentChapter: position.chapter,
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: pickReference,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        '${book.name} ${position.chapter}',
                        style: AppTextStyles.headlineSmall
                            .copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(PhosphorIcons.caretDown(), color: colorScheme.primary),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Split view',
            icon: Icon(
              splitActive ? PhosphorIcons.x() : PhosphorIcons.columns(),
              color: colorScheme.primary,
            ),
            onPressed: onSplit,
          ),
          PopupMenuButton<String>(
            tooltip: 'Edition',
            initialValue: position.editionId,
            onSelected: (id) =>
                ref.read(bibleReadingPositionProvider.notifier).setEdition(id),
            itemBuilder: (context) => [
              for (final e in editions)
                PopupMenuItem(value: e.id, child: Text(e.displayName)),
            ],
            child: Chip(
              label: Text(position.editionId.toUpperCase()),
              avatar: Icon(PhosphorIcons.translate(), size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

/// Header shown while split is open: orientation toggle + close button +
/// the primary reference so the user always knows what's on the left/top.
class _SplitHeader extends StatelessWidget {
  const _SplitHeader({
    required this.orientation,
    required this.onOrientationChanged,
    required this.onClose,
    required this.primaryReference,
    required this.onPickPrimary,
    required this.onSwap,
  });

  final SplitOrientation orientation;
  final ValueChanged<SplitOrientation> onOrientationChanged;
  final VoidCallback onClose;
  final String primaryReference;
  final VoidCallback onPickPrimary;
  final VoidCallback? onSwap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onPickPrimary,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        primaryReference,
                        style: AppTextStyles.titleMedium
                            .copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      PhosphorIcons.caretDown(),
                      size: 20,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Swap panes',
            icon: Icon(PhosphorIcons.arrowsLeftRight()),
            onPressed: onSwap,
          ),
          SplitOrientationToggle(
            orientation: orientation,
            onChanged: onOrientationChanged,
          ),
          IconButton(
            tooltip: 'Close split',
            icon: Icon(PhosphorIcons.x()),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

/// The right (or bottom) pane in Bible split: either a picker (when no
/// secondary chapter is selected) or the chapter renderer.
class _SecondaryBiblePane extends ConsumerWidget {
  const _SecondaryBiblePane({
    required this.state,
    required this.textScale,
    required this.onPicked,
    required this.onEditionChanged,
    required this.onChange,
  });

  final _BibleSplitState state;
  final double textScale;
  final void Function(String editionId, String bookCode, int chapter) onPicked;
  final ValueChanged<String> onEditionChanged;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editionId = state.secondaryEditionId;
    if (editionId == null) return const SizedBox.shrink();

    if (!state.hasSecondaryChapter) {
      return BiblePickerInline(
        editionId: editionId,
        onPicked: onPicked,
        onEditionChanged: onEditionChanged,
      );
    }

    final manifestAsync = ref.watch(bibleManifestProvider(editionId));
    return manifestAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load edition: $e')),
      data: (manifest) {
        final book = manifest.books.firstWhere(
          (b) => b.code == state.secondaryBookCode,
          orElse: () => manifest.books.first,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${book.name} ${state.secondaryChapter} · ${editionId.toUpperCase()}',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onChange,
                    style: TextButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).colorScheme.secondary,
                    ),
                    icon: Icon(PhosphorIcons.arrowsLeftRight(), size: 18),
                    label: const Text('Change'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BibleChapterView(
                editionId: editionId,
                bookCode: book.code,
                chapter: state.secondaryChapter!,
                textScale: textScale,
                highlights: ref
                        .watch(verseHighlightsProvider((
                          bookCode: book.code,
                          chapter: state.secondaryChapter!,
                        )))
                        .valueOrNull ??
                    const <int, BibleAnnotation>{},
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Shown in place of the header while verses are selected: a count plus share
/// and clear actions. Builds the citation + joined verse text on share.
class _SelectionBar extends ConsumerWidget {
  const _SelectionBar({
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
    final colorScheme = Theme.of(context).colorScheme;
    final query = (editionId: editionId, bookCode: book.code, chapter: chapter);
    final chapterData = ref.watch(bibleChapterProvider(query)).valueOrNull;
    final highlights = ref
            .watch(verseHighlightsProvider(
              (bookCode: book.code, chapter: chapter),
            ))
            .valueOrNull ??
        const <int, BibleAnnotation>{};
    final anyHighlighted = selected.any(highlights.containsKey);

    String verseRef(int v) => '${book.code}.$chapter.$v';
    int anchorVerse() => selected.reduce((a, b) => a < b ? a : b);

    Future<void> applyColor(HighlightColor c) async {
      final dao = ref.read(bibleAnnotationsDaoProvider);
      for (final v in selected) {
        await dao.setHighlight(verseRef(v), c.key);
      }
      onClear();
    }

    Future<void> clearHighlight() async {
      final dao = ref.read(bibleAnnotationsDaoProvider);
      for (final v in selected) {
        await dao.removeHighlight(verseRef(v));
      }
      onClear();
    }

    // Tie the verse(s) to a new tablet: default-highlight them yellow (an
    // explicit verse->note link deserves a visible mark) and open the editor
    // pre-filled with the bible link, which note_links picks up on save so the
    // Phase C backlink indicator surfaces this tablet.
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

    return Material(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 8, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Clear selection',
                  icon: Icon(PhosphorIcons.x()),
                  onPressed: onClear,
                ),
                Expanded(
                  child: Text(
                    '${selected.length} selected',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: chapterData == null ? null : share,
                  icon: Icon(PhosphorIcons.export(), size: 18),
                  label: const Text('Share'),
                ),
              ],
            ),
            const SizedBox(height: 2),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  for (final c in HighlightColor.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => applyColor(c),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: c.swatch,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  IconButton(
                    tooltip: 'Remove highlight',
                    onPressed: anyHighlighted ? clearHighlight : null,
                    icon: Icon(PhosphorIcons.highlighter()),
                  ),
                  TextButton.icon(
                    onPressed: addNote,
                    icon: Icon(PhosphorIcons.notePencil(), size: 18),
                    label: const Text('Add note'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Previous / next chapter, crossing book boundaries via the manifest.
class _ChapterNav extends ConsumerWidget {
  const _ChapterNav({
    required this.manifest,
    required this.book,
    required this.chapter,
  });

  final BibleManifest manifest;
  final BibleBookInfo book;
  final int chapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(bibleReadingPositionProvider.notifier);
    final books = manifest.books;
    final bookIndex = books.indexWhere((b) => b.ordinal == book.ordinal);

    void goPrev() {
      if (chapter > 1) {
        notifier.openChapter(book.code, chapter - 1);
      } else if (bookIndex > 0) {
        final prev = books[bookIndex - 1];
        notifier.openChapter(prev.code, prev.chapterCount);
      }
    }

    void goNext() {
      if (chapter < book.chapterCount) {
        notifier.openChapter(book.code, chapter + 1);
      } else if (bookIndex < books.length - 1) {
        final next = books[bookIndex + 1];
        notifier.openChapter(next.code, 1);
      }
    }

    final hasPrev = chapter > 1 || bookIndex > 0;
    final hasNext = chapter < book.chapterCount || bookIndex < books.length - 1;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: hasPrev ? goPrev : null,
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.secondary,
              ),
              icon: Icon(PhosphorIcons.caretLeft()),
              label: const Text('Previous'),
            ),
            TextButton(
              onPressed: hasNext ? goNext : null,
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.secondary,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Next'),
                  const SizedBox(width: 4),
                  Icon(PhosphorIcons.caretRight()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIcons.warningCircle(), size: 48, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(message, style: AppTextStyles.bodyLarge),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/// Lists the tablets that link to a given verse; tapping a row opens that
/// tablet in the editor.
class _BacklinksSheet extends StatelessWidget {
  const _BacklinksSheet({required this.reference, required this.items});

  final String reference;
  final List<BibleBacklink> items;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(
              'Linked from $reference',
              style: AppTextStyles.titleMedium
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          for (final item in items)
            ListTile(
              leading: Icon(PhosphorIcons.note()),
              title: Text(
                item.noteTitle.trim().isEmpty
                    ? 'Untitled tablet'
                    : item.noteTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.of(context).pop();
                context.router.push(TabletEditorRoute(noteId: item.noteId));
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
