import 'package:material_ui/material_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/widgets/lum_circle_button.dart';
import 'package:openbaptisthymnal/core/widgets/split_orientation_toggle.dart';
import 'package:openbaptisthymnal/core/widgets/split_pane.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';
import 'package:openbaptisthymnal/features/bible/providers/verse_highlights_provider.dart';
import 'package:openbaptisthymnal/features/bible/ui/bible_strings.dart';
import 'package:openbaptisthymnal/features/bible/ui/widgets/bible_chapter_view.dart';
import 'package:openbaptisthymnal/features/bible/ui/widgets/bible_picker_inline.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Ephemeral split state for the Bible tab: the user opens a second pane,
/// flips between vertical and horizontal layouts, and picks a different
/// edition/book/chapter for the secondary pane.
class BibleSplitState {
  const BibleSplitState({
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

  static const initial = BibleSplitState(
    isOpen: false,
    orientation: SplitOrientation.vertical,
    secondaryEditionId: null,
    secondaryBookCode: null,
    secondaryChapter: null,
  );

  BibleSplitState copyWith({
    bool? isOpen,
    SplitOrientation? orientation,
    String? secondaryEditionId,
    String? secondaryBookCode,
    int? secondaryChapter,
    bool clearSecondaryChapter = false,
  }) =>
      BibleSplitState(
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

/// Header while split is open: back (pushed route), orientation toggle, swap
/// and close. Each control is a 48pt target.
class SplitHeader extends StatelessWidget {
  const SplitHeader({
    super.key,
    required this.orientation,
    required this.onOrientationChanged,
    required this.onClose,
    required this.onSwap,
    this.onBack,
  });

  final SplitOrientation orientation;
  final ValueChanged<SplitOrientation> onOrientationChanged;
  final VoidCallback onClose;
  final VoidCallback? onSwap;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          LumSize.screenGutter, LumSpace.sm, LumSize.screenGutter, LumSpace.sm),
      child: Row(
        children: [
          if (onBack != null) ...[
            LumCircleButton(
              icon: PhosphorIcons.caretLeft(),
              label: BibleStrings.back,
              onPressed: onBack,
            ),
            const SizedBox(width: LumSpace.sm),
          ],
          Expanded(
            child: Center(
              child: SplitOrientationToggle(
                orientation: orientation,
                onChanged: onOrientationChanged,
              ),
            ),
          ),
          LumCircleButton(
            icon: PhosphorIcons.arrowsLeftRight(),
            label: BibleStrings.swapPanes,
            onPressed: onSwap,
          ),
          const SizedBox(width: LumSpace.sm),
          LumCircleButton(
            icon: PhosphorIcons.x(),
            label: BibleStrings.closeSplit,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

/// Small caps label over a pane ("JOHN 15 · ENGLISH · KJV"). When [onTap] is
/// set the whole label is a button that changes what the pane shows.
class PaneHeader extends StatelessWidget {
  const PaneHeader({super.key, required this.label, this.onTap, this.hint});

  final String label;
  final VoidCallback? onTap;

  /// Screen reader hint for the tap, e.g. "Change".
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    final text = Row(
      children: [
        Expanded(
          child: Text(label.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: LumText.roadLabelCaps11.copyWith(color: c.textSecondary)),
        ),
        if (onTap != null) ...[
          const SizedBox(width: LumSpace.xs),
          Icon(PhosphorIcons.caretDown(), size: 14, color: c.textSecondary),
        ],
      ],
    );
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(LumSpace.lg, LumSpace.xs, LumSpace.md, 0),
      child: Semantics(
        button: onTap != null,
        label: onTap == null ? label : '$label, ${hint ?? BibleStrings.change}',
        excludeSemantics: true,
        onTap: onTap,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: LumSize.touchTarget),
            child: Align(alignment: Alignment.centerLeft, child: text),
          ),
        ),
      ),
    );
  }
}

/// The right (or bottom) pane in Bible split: either a picker (when no
/// secondary chapter is selected) or the chapter renderer.
class SecondaryBiblePane extends ConsumerWidget {
  const SecondaryBiblePane({
    super.key,
    required this.state,
    required this.textScale,
    required this.onPicked,
    required this.onEditionChanged,
    required this.onChange,
    this.bottomPadding = 120,
  });

  /// Room under the text for a docked panel (Mark read).
  final double bottomPadding;
  final BibleSplitState state;
  final double textScale;
  final void Function(String editionId, String bookCode, int chapter) onPicked;
  final ValueChanged<String> onEditionChanged;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lum;
    final savedId = state.secondaryEditionId;
    if (savedId == null) return const SizedBox.shrink();
    // A companion edition that was removed while open reads as the fallback.
    final editionId =
        ref.watch(bibleEditionsProvider).any((e) => e.id == savedId)
            ? savedId
            : kFallbackEditionId;

    if (!state.hasSecondaryChapter) {
      return BiblePickerInline(
        editionId: editionId,
        onPicked: onPicked,
        onEditionChanged: onEditionChanged,
      );
    }

    final manifestAsync = ref.watch(bibleManifestProvider(editionId));
    final edition = ref.watch(bibleRepositoryProvider).editionById(editionId);
    return manifestAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(BibleStrings.loadError,
            style: LumText.body.copyWith(color: c.textSecondary)),
      ),
      data: (manifest) {
        final book = manifest.books.firstWhere(
          (b) => b.code == state.secondaryBookCode,
          orElse: () => manifest.books.first,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PaneHeader(
              label:
                  '${book.name} ${state.secondaryChapter} · ${edition == null ? editionId : BibleStrings.languageAndVersion(edition)}',
              onTap: onChange,
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
                padding: EdgeInsets.fromLTRB(
                    LumSpace.sm, LumSpace.sm, LumSpace.sm, bottomPadding),
              ),
            ),
          ],
        );
      },
    );
  }
}
