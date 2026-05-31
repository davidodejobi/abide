import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/core/theme/font_scale_provider.dart';
import 'package:openbaptisthymnal/features/bible/domain/verse_reference_format.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_chapter.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';
import 'package:openbaptisthymnal/features/bible/ui/widgets/book_picker_sheet.dart';
import 'package:openbaptisthymnal/features/bible/ui/widgets/chapter_picker_sheet.dart';

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

    // Selected verse numbers for the chapter currently in view. Reset whenever
    // the reader moves to a different edition, book, or chapter.
    final selected = useState<Set<int>>(<int>{});
    useEffect(() {
      selected.value = <int>{};
      return null;
    }, [position.editionId, position.ordinal, position.chapter]);

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
          (b) => b.ordinal == position.ordinal,
          orElse: () => manifest.books.first,
        );
        return Column(
          children: [
            if (selected.value.isEmpty)
              _ReaderHeader(manifest: manifest, book: book)
            else
              _SelectionBar(
                editionId: position.editionId,
                book: book,
                chapter: position.chapter,
                selected: selected.value,
                onClear: () => selected.value = <int>{},
              ),
            Expanded(
              child: _ChapterView(
                editionId: position.editionId,
                book: book,
                chapter: position.chapter,
                selected: selected.value,
                textScale: textScale,
                onTapVerse: onTapVerse,
                onLongPressVerse: onLongPressVerse,
              ),
            ),
            _ChapterNav(
                manifest: manifest, book: book, chapter: position.chapter),
          ],
        );
      },
    );
  }
}

/// Book + chapter selector and an edition switch.
class _ReaderHeader extends ConsumerWidget {
  const _ReaderHeader({required this.manifest, required this.book});

  final BibleManifest manifest;
  final BibleBookInfo book;

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
          .openChapter(ordinal, chapter);
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
        (editionId: editionId, ordinal: book.ordinal, chapter: chapter);
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

class _ChapterView extends ConsumerWidget {
  const _ChapterView({
    required this.editionId,
    required this.book,
    required this.chapter,
    required this.selected,
    required this.textScale,
    required this.onTapVerse,
    required this.onLongPressVerse,
  });

  final String editionId;
  final BibleBookInfo book;
  final int chapter;
  final Set<int> selected;
  final double textScale;
  final ValueChanged<int> onTapVerse;
  final ValueChanged<int> onLongPressVerse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query =
        (editionId: editionId, ordinal: book.ordinal, chapter: chapter);
    final chapterAsync = ref.watch(bibleChapterProvider(query));
    final colorScheme = Theme.of(context).colorScheme;

    return chapterAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      ),
      error: (e, _) => _ErrorView(
        message: 'Failed to load this chapter',
        onRetry: () => ref.invalidate(bibleChapterProvider(query)),
      ),
      data: (data) => _VerseList(
        chapter: data,
        selected: selected,
        textScale: textScale,
        onTapVerse: onTapVerse,
        onLongPressVerse: onLongPressVerse,
      ),
    );
  }
}

class _VerseList extends StatelessWidget {
  const _VerseList({
    required this.chapter,
    required this.selected,
    required this.textScale,
    required this.onTapVerse,
    required this.onLongPressVerse,
  });

  final BibleChapter chapter;
  final Set<int> selected;
  final double textScale;
  final ValueChanged<int> onTapVerse;
  final ValueChanged<int> onLongPressVerse;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.builder(
      // Keying on the chapter resets the scroll offset to the top on every
      // chapter change, so the reader always starts at verse 1.
      key: ValueKey('${chapter.book}.${chapter.chapter}'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      itemCount: chapter.verses.length,
      itemBuilder: (context, index) {
        final verse = chapter.verses[index];
        final isSelected = selected.contains(verse.number);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTapVerse(verse.number),
          onLongPress: () => onLongPressVerse(verse.number),
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
                  fontFamily: AppTextStyles.fontFamilyEBGaramond,
                  fontSize: 20 * textScale,
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
        notifier.openChapter(book.ordinal, chapter - 1);
      } else if (bookIndex > 0) {
        final prev = books[bookIndex - 1];
        notifier.openChapter(prev.ordinal, prev.chapterCount);
      }
    }

    void goNext() {
      if (chapter < book.chapterCount) {
        notifier.openChapter(book.ordinal, chapter + 1);
      } else if (bookIndex < books.length - 1) {
        final next = books[bookIndex + 1];
        notifier.openChapter(next.ordinal, 1);
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
