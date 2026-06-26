import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/core/theme/font_scale_provider.dart';
import 'package:openbaptisthymnal/core/widgets/split_orientation_toggle.dart';
import 'package:openbaptisthymnal/core/widgets/split_pane.dart';
import 'package:openbaptisthymnal/features/bible/domain/verse_reference_format.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';
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
    useEffect(() {
      selected.value = <int>{};
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
      split.value =
          split.value.copyWith(secondaryEditionId: editionId);
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

        final primaryView = BibleChapterView(
          editionId: position.editionId,
          bookCode: book.code,
          chapter: position.chapter,
          textScale: textScale,
          selected: selected.value,
          onTapVerse: onTapVerse,
          onLongPressVerse: onLongPressVerse,
        );

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
              Expanded(child: primaryView),
              _ChapterNav(
                  manifest: manifest, book: book, chapter: position.chapter),
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
              ),
              Expanded(
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

    Future<void> pickReference() async {
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
        currentChapter: ordinal == book.ordinal ? position.chapter : 1,
      );
      if (chapter == null) return;
      ref
          .read(bibleReadingPositionProvider.notifier)
          .openChapter(picked.code, chapter);
    }

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
                    Icon(Icons.expand_more, color: colorScheme.primary),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Split view',
            icon: Icon(
              splitActive
                  ? Icons.close_rounded
                  : Icons.vertical_split_rounded,
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
              avatar: const Icon(Icons.translate, size: 18),
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
  });

  final SplitOrientation orientation;
  final ValueChanged<SplitOrientation> onOrientationChanged;
  final VoidCallback onClose;
  final String primaryReference;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              primaryReference,
              style: AppTextStyles.titleMedium
                  .copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SplitOrientationToggle(
            orientation: orientation,
            onChanged: onOrientationChanged,
          ),
          IconButton(
            tooltip: 'Close split',
            icon: const Icon(Icons.close_rounded),
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
      loading: () =>
          const Center(child: CircularProgressIndicator()),
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
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
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
    final query =
        (editionId: editionId, bookCode: book.code, chapter: chapter);
    final chapterData = ref.watch(bibleChapterProvider(query)).valueOrNull;

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
        padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Clear selection',
              icon: const Icon(Icons.close),
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
              icon: const Icon(Icons.ios_share, size: 18),
              label: const Text('Share'),
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

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: hasPrev ? goPrev : null,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Previous'),
            ),
            TextButton.icon(
              onPressed: hasNext ? goNext : null,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Next'),
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
          Icon(Icons.error_outline, size: 48, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(message, style: AppTextStyles.bodyLarge),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
