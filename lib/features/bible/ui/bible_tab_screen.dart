import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/providers/bottom_nav_provider.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/note_links_dao.dart';
import 'package:openbaptisthymnal/core/theme/font_scale_provider.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/widgets/lum_button.dart';
import 'package:openbaptisthymnal/core/widgets/split_pane.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';
import 'package:openbaptisthymnal/features/bible/providers/verse_backlinks_provider.dart';
import 'package:openbaptisthymnal/features/bible/providers/verse_highlights_provider.dart';
import 'package:openbaptisthymnal/features/bible/ui/bible_strings.dart';
import 'package:openbaptisthymnal/features/bible/ui/widgets/backlinks_sheet.dart';
import 'package:openbaptisthymnal/features/bible/ui/widgets/bible_chapter_view.dart';
import 'package:openbaptisthymnal/features/bible/ui/widgets/bible_split.dart';
import 'package:openbaptisthymnal/features/bible/ui/widgets/book_picker_sheet.dart';
import 'package:openbaptisthymnal/features/bible/ui/widgets/chapter_nav_bar.dart';
import 'package:openbaptisthymnal/features/bible/ui/widgets/chapter_picker_sheet.dart';
import 'package:openbaptisthymnal/features/bible/ui/widgets/edition_sheet.dart';
import 'package:openbaptisthymnal/features/bible/ui/widgets/mark_read_dock.dart';
import 'package:openbaptisthymnal/features/bible/ui/widgets/reader_top_bar.dart';
import 'package:openbaptisthymnal/features/bible/ui/widgets/verse_action_bar.dart';
import 'package:openbaptisthymnal/features/daily/domain/passage_label.dart';
import 'package:openbaptisthymnal/features/daily/providers/daily_providers.dart';
import 'package:openbaptisthymnal/features/settings/ui/widgets/text_size_sheet.dart';

/// The Bible reading tab (Figma M3-01): a top row, the big chapter title and
/// the text on the calm page, with a glass chapter nav floating under it. The
/// reading position is persisted, so the tab reopens where the reader left off.
///
/// Long-pressing a verse starts a selection; further taps add or remove verses
/// and the nav becomes the glass verse actions (M3-03). Verse text size follows
/// the app-wide [fontScaleProvider].
///
/// When [planId] and [dayIndex] are given (Start reading on Today) the reader
/// shows the day, the chapter count and the gold Mark read (M3-02).
@RoutePage()
class BibleTabScreen extends HookConsumerWidget {
  const BibleTabScreen({
    super.key,
    this.controlsAppNav = true,
    this.planId,
    this.dayIndex,
  });

  /// Whether this instance may hide the app's floating bottom nav bar.
  ///
  /// True for the dashboard's Bible tab, which sits *behind* that bar and should
  /// get it out of the way while reading.
  ///
  /// **False for [BibleReaderPage]**, which renders this very same widget as a
  /// pushed full-screen route. That page has no bottom nav of its own, so hiding
  /// the dashboard's from here does nothing visible at the time -- and then the
  /// user pops back to a dashboard whose nav bar is simply gone, with no way to
  /// bring it back except returning to the Bible tab and scrolling up.
  final bool controlsAppNav;

  /// The plan day this reader was opened from, if any.
  final String? planId;
  final int? dayIndex;

  bool get _fromPlan => planId != null && dayIndex != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useAutomaticKeepAlive();

    final position = ref.watch(bibleReadingPositionProvider);
    final manifestAsync = ref.watch(bibleManifestProvider(position.editionId));
    final textScale = ref.watch(fontScaleProvider).scale;
    final c = context.lum;
    final editions = ref.watch(bibleEditionsProvider);
    final missingEdition = ref.watch(missingSavedEditionProvider);
    final split = useState(BibleSplitState.initial);
    final isPushed = !controlsAppNav;

    final selected = useState<Set<int>>(<int>{});
    // Bottom chrome (chapter nav + the app's glass tab bar) auto-hides while
    // reading down, returns on scroll up and on every chapter change.
    //
    // The visible/hidden flag is LOCAL; the global bottomNavVisibleProvider is
    // a mirror this screen writes to only when it actually owns that bar (see
    // [controlsAppNav]).
    final chromeVisible = useState(true);

    void setChromeVisible(bool visible) {
      if (chromeVisible.value == visible) return;
      chromeVisible.value = visible;
      if (controlsAppNav) {
        ref.read(bottomNavVisibleProvider.notifier).state = visible;
      }
    }

    useEffect(() {
      selected.value = <int>{};
      // Deferred: provider writes are not allowed during build.
      Future.microtask(() => setChromeVisible(true));
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
      split.value = BibleSplitState(
        isOpen: true,
        orientation: SplitOrientation.vertical,
        secondaryEditionId: otherEdition(position.editionId),
        secondaryBookCode: position.bookCode,
        secondaryChapter: position.chapter,
      );
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

    // Plan-day context (M3-02).
    final plan =
        _fromPlan ? ref.watch(planByIdProvider(planId!)).valueOrNull : null;
    final planDay = plan?.dayAt(dayIndex ?? 0);
    final bookNames = ref.watch(planBookNamesProvider).valueOrNull ?? const {};
    final streak = ref.watch(streakProvider);
    final todayDone = ref.watch(isTodayCompleteProvider);

    final saving = useRef(false);
    final dockKey = useMemoized(GlobalKey.new);
    // The real height of the Mark read dock, so the text can scroll clear of it.
    final dockHeight = useState(220.0);

    void measureDock() {
      final h = (dockKey.currentContext?.size)?.height;
      if (h != null && h != dockHeight.value) dockHeight.value = h;
    }

    useEffect(() {
      if (_fromPlan) {
        WidgetsBinding.instance.addPostFrameCallback((_) => measureDock());
      }
      return null;
    });

    Future<void> markRead() async {
      if (saving.value) return; // a second tap while saving is ignored
      saving.value = true;
      try {
        await ref.read(markPlanDayReadProvider)(planId!, dayIndex!);
        if (context.mounted && ModalRoute.of(context)?.isCurrent == true) {
          Navigator.of(context).pop(true);
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              const SnackBar(content: Text(BibleStrings.markReadFailed)));
        }
      } finally {
        saving.value = false;
      }
    }

    return manifestAsync.when(
      loading: () =>
          Center(child: CircularProgressIndicator(color: c.textSecondary)),
      error: (e, _) => _ErrorView(
        message: BibleStrings.loadError,
        onRetry: () =>
            ref.invalidate(bibleManifestProvider(position.editionId)),
      ),
      data: (manifest) {
        final book = manifest.books.firstWhere(
          (b) => b.code == position.bookCode,
          orElse: () => manifest.books.first,
        );
        final edition =
            ref.watch(bibleRepositoryProvider).editionById(position.editionId);
        final editionChip = edition == null
            ? position.editionId.toUpperCase()
            : BibleStrings.versionCode(edition);

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
            isScrollControlled: true,
            builder: (_) => BacklinksSheet(
              reference: '${book.name} ${position.chapter}:$verse',
              items: items,
            ),
          );
        }

        final books = manifest.books;
        final bookIndex = books.indexWhere((b) => b.ordinal == book.ordinal);
        final notifier = ref.read(bibleReadingPositionProvider.notifier);

        void goPrev() {
          if (position.chapter > 1) {
            notifier.openChapter(book.code, position.chapter - 1);
          } else if (bookIndex > 0) {
            final prev = books[bookIndex - 1];
            notifier.openChapter(prev.code, prev.chapterCount);
          }
        }

        void goNext() {
          if (position.chapter < book.chapterCount) {
            notifier.openChapter(book.code, position.chapter + 1);
          } else if (bookIndex < books.length - 1) {
            notifier.openChapter(books[bookIndex + 1].code, 1);
          }
        }

        final hasPrev = position.chapter > 1 || bookIndex > 0;
        final hasNext = position.chapter < book.chapterCount ||
            bookIndex < books.length - 1;

        Future<void> pickReference() => _pickPrimaryReference(
              context,
              ref,
              manifest: manifest,
              book: book,
              currentChapter: position.chapter,
            );

        Future<void> pickEdition() async {
          final id = await showEditionSheet(context,
              editions: editions,
              currentId: position.editionId,
              canGetMore: !kIsWeb);
          if (id == kGetMoreBibles) {
            if (context.mounted) context.router.push(const MoreBiblesRoute());
          } else if (id != null) {
            notifier.setEdition(id);
          }
        }

        // "Chapter 1 of 3" for the plan day, when this chapter is part of it.
        String? chapterEyebrow;
        // The dock's prev/next stay inside the plan day while the reader is in it.
        VoidCallback? dockPrev = hasPrev ? goPrev : null;
        VoidCallback? dockNext = hasNext ? goNext : null;
        if (planDay != null) {
          final chapters = [
            for (final p in planDay.passages)
              for (var ch = p.start.chapter; ch <= p.end.chapter; ch++)
                (p.start.book, ch),
          ];
          final i = chapters.indexOf((book.code, position.chapter));
          if (i >= 0) {
            chapterEyebrow = BibleStrings.chapterOf(i + 1, chapters.length);
            dockPrev = i > 0
                ? () =>
                    notifier.openChapter(chapters[i - 1].$1, chapters[i - 1].$2)
                : null;
            dockNext = i < chapters.length - 1
                ? () =>
                    notifier.openChapter(chapters[i + 1].$1, chapters[i + 1].$2)
                : null;
          }
        }

        // Where the floating bottom layer sits: above the app tab bar on the
        // tab, above the home indicator on the pushed route.
        final safeBottom = MediaQuery.paddingOf(context).bottom;
        final barBottom = (controlsAppNav
                ? (safeBottom < 8 ? 8 : safeBottom) + LumSize.tabBar
                : safeBottom) +
            LumSpace.md;
        final textBottomPad = _fromPlan
            ? dockHeight.value + LumSpace.md
            : barBottom + 56 + LumSpace.xl;
        final splitBottomPad =
            _fromPlan ? dockHeight.value + LumSpace.md : 120.0;
        final textPadding = EdgeInsets.fromLTRB(LumSize.screenGutter - 4,
            LumSpace.sm, LumSize.screenGutter - 4, textBottomPad);
        final isSelecting = selected.value.isNotEmpty;

        String titleFor(BibleBookInfo b, int chapter) => '${b.name} $chapter';

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
          padding: split.value.isOpen
              ? EdgeInsets.fromLTRB(
                  LumSpace.sm, LumSpace.sm, LumSpace.sm, splitBottomPad)
              : textPadding,
          header: split.value.isOpen
              ? null
              : ChapterTitle(
                  title: titleFor(book, position.chapter),
                  eyebrow: chapterEyebrow,
                  onTap: pickReference,
                ),
        );

        // Flat chapter list across the whole edition so a PageView can swipe
        // continuously through chapters and across book boundaries.
        final chapterRefs = [
          for (final b in books)
            for (var ch = 1; ch <= b.chapterCount; ch++) (book: b, chapter: ch),
        ];
        var currentIndex = position.chapter - 1;
        for (var i = 0; i < bookIndex; i++) {
          currentIndex += books[i].chapterCount;
        }

        final Widget content;
        if (!split.value.isOpen) {
          content = NotificationListener<UserScrollNotification>(
            onNotification: (n) {
              if (n.metrics.axis != Axis.vertical) return false;
              if (n.direction == ScrollDirection.reverse) {
                setChromeVisible(false);
              } else if (n.direction == ScrollDirection.forward) {
                setChromeVisible(true);
              }
              return false;
            },
            child: _ChapterPager(
              key: ValueKey(position.editionId),
              index: currentIndex,
              itemCount: chapterRefs.length,
              canSwipe: !isSelecting,
              onIndexChanged: (i) {
                HapticFeedback.selectionClick();
                final target = chapterRefs[i];
                notifier.openChapter(target.book.code, target.chapter);
              },
              itemBuilder: (context, i) {
                if (i == currentIndex) return primaryView;
                final target = chapterRefs[i];
                return BibleChapterView(
                  editionId: position.editionId,
                  bookCode: target.book.code,
                  chapter: target.chapter,
                  textScale: textScale,
                  padding: textPadding,
                  header: ChapterTitle(
                      title: titleFor(target.book, target.chapter)),
                );
              },
            ),
          );
        } else {
          content = GestureDetector(
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
              primary: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PaneHeader(
                    label:
                        '${titleFor(book, position.chapter)} · ${edition == null ? position.editionId : BibleStrings.languageAndVersion(edition)}',
                    onTap: pickReference,
                  ),
                  Expanded(child: primaryView),
                ],
              ),
              secondary: SecondaryBiblePane(
                bottomPadding: splitBottomPad,
                state: split.value,
                textScale: textScale,
                onPicked: (e, b, ch) => split.value = split.value.copyWith(
                  secondaryEditionId: e,
                  secondaryBookCode: b,
                  secondaryChapter: ch,
                ),
                onEditionChanged: (e) =>
                    split.value = split.value.copyWith(secondaryEditionId: e),
                onChange: () => split.value =
                    split.value.copyWith(clearSecondaryChapter: true),
              ),
            ),
          );
        }

        final navLabel = '${book.name} ${position.chapter}';
        final Widget bottom;
        if (isSelecting) {
          bottom = VerseActionBar(
            editionId: position.editionId,
            book: book,
            chapter: position.chapter,
            selected: selected.value,
            onClear: () => selected.value = <int>{},
          );
        } else {
          bottom = ChapterNavBar(
            reference: navLabel,
            edition: editionChip,
            onPrev: hasPrev ? goPrev : null,
            onNext: hasNext ? goNext : null,
            onPick: pickReference,
          );
        }
        final hideBar = !chromeVisible.value && !isSelecting && controlsAppNav;

        String? streakLine;
        if (_fromPlan) {
          streakLine = BibleStrings.litDay(
              todayDone ? streak.current : streak.current + 1);
        }

        return Stack(
          children: [
            Column(
              children: [
                if (split.value.isOpen)
                  SplitHeader(
                    orientation: split.value.orientation,
                    onOrientationChanged: (o) =>
                        split.value = split.value.copyWith(orientation: o),
                    onClose: () => split.value = BibleSplitState.initial,
                    onSwap: split.value.hasSecondaryChapter ? swapPanes : null,
                    onBack: isPushed
                        ? () => Navigator.of(context).maybePop()
                        : null,
                  )
                else
                  ReaderTopBar(
                    editionChip: editionChip,
                    planLabel: planDay == null
                        ? null
                        : BibleStrings.dayAndPassage(planDay.dayIndex,
                            formatPassages(planDay.passages, bookNames)),
                    onBack: isPushed
                        ? () => Navigator.of(context).maybePop()
                        : null,
                    onSplit: openSplit,
                    onTextSize: () => showTextSizeSheet(context,
                        title: BibleStrings.textSizeTitle),
                    onEdition: pickEdition,
                  ),
                if (missingEdition != null)
                  _MissingEditionBanner(
                    onGet: kIsWeb
                        ? null
                        : () => context.router.push(const MoreBiblesRoute()),
                  ),
                Expanded(child: content),
              ],
            ),
            if (_fromPlan && !isSelecting)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: NotificationListener<SizeChangedLayoutNotification>(
                  onNotification: (_) {
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => measureDock());
                    return false;
                  },
                  child: SizeChangedLayoutNotifier(
                    child: MarkReadDock(
                      key: dockKey,
                      streakLine: streakLine,
                      onMarkRead: markRead,
                      onPrev: dockPrev,
                      onNext: dockNext,
                    ),
                  ),
                ),
              )
            else
              Positioned(
                // The verse actions are wider than the nav, so they sit closer
                // to the edges.
                left: isSelecting ? LumSpace.md : LumSize.screenGutter,
                right: isSelecting ? LumSpace.md : LumSize.screenGutter,
                bottom: barBottom,
                child: AnimatedSlide(
                  offset: hideBar ? const Offset(0, 2.5) : Offset.zero,
                  duration: LumMotion.base,
                  curve: Curves.easeOut,
                  child: bottom,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Book -> chapter picker flow for the primary reading position.
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
    final jumping = useRef(false);

    useEffect(() {
      if (!controller.hasClients) return null;
      final page = controller.page?.round();
      if (page == null || page == index) return null;
      if ((page - index).abs() == 1) {
        controller.animateToPage(
          index,
          duration: LumMotion.base,
          curve: Curves.easeOut,
        );
      } else {
        jumping.value = true;
        controller.jumpToPage(index);
        jumping.value = false;
      }
      return null;
    }, [index]);

    return PageView.builder(
      controller: controller,
      physics: canSwipe ? null : const NeverScrollableScrollPhysics(),
      // A programmatic jump is not a swipe: the position is already right.
      onPageChanged: (i) {
        if (!jumping.value) onIndexChanged(i);
      },
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LumSize.screenGutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message,
                textAlign: TextAlign.center,
                style: LumText.body.copyWith(color: c.textPrimary)),
            const SizedBox(height: LumSpace.lg),
            LumButton(
              label: BibleStrings.retry,
              kind: LumButtonKind.secondary,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

/// Gentle nudge shown when the saved edition is not on this phone and the
/// reader has fallen back to the KJV.
class _MissingEditionBanner extends StatelessWidget {
  const _MissingEditionBanner({required this.onGet});

  final VoidCallback? onGet;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Container(
      margin: const EdgeInsets.fromLTRB(
          LumSize.screenGutter, LumSpace.xs, LumSize.screenGutter, 0),
      padding: const EdgeInsets.symmetric(
          horizontal: LumSpace.lg, vertical: LumSpace.sm),
      decoration: BoxDecoration(
        color: c.bgSurface,
        borderRadius: BorderRadius.circular(LumRadius.xl),
        border: Border.all(color: c.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(BibleStrings.missingEditionNotice,
                style: LumText.footnote.copyWith(color: c.textSecondary)),
          ),
          if (onGet != null)
            TextButton(
              onPressed: onGet,
              child: Text(BibleStrings.getIt,
                  style: LumText.footnoteEmphasized
                      .copyWith(color: c.textPrimary)),
            ),
        ],
      ),
    );
  }
}
