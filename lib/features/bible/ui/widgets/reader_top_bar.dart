import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/widgets/lum_circle_button.dart';
import 'package:openbaptisthymnal/features/bible/ui/bible_strings.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Top row of the reader: back (pushed route only), the edition chip (or a
/// plain label when reading from a plan day), split and text size.
class ReaderTopBar extends StatelessWidget {
  const ReaderTopBar({
    super.key,
    required this.editionChip,
    this.planLabel,
    this.onBack,
    required this.onSplit,
    required this.onTextSize,
    required this.onEdition,
  });

  /// "KJV".
  final String editionChip;

  /// "DAY 41 · JOHN 15–17" shown instead of the chip when reading a plan day.
  final String? planLabel;
  final VoidCallback? onBack;
  final VoidCallback onSplit;
  final VoidCallback onTextSize;
  final VoidCallback onEdition;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          LumSize.screenGutter, LumSpace.sm, LumSize.screenGutter, 0),
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
              child: planLabel != null
                  ? Text(planLabel!,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: LumText.roadLabelCaps11
                          .copyWith(color: c.textSecondary))
                  : _EditionChip(label: editionChip, onTap: onEdition),
            ),
          ),
          LumCircleButton(
            icon: PhosphorIcons.columns(),
            label: BibleStrings.splitView,
            onPressed: onSplit,
          ),
          const SizedBox(width: LumSpace.sm),
          LumCircleButton(
            icon: PhosphorIcons.textAa(),
            label: BibleStrings.textSize,
            onPressed: onTextSize,
          ),
        ],
      ),
    );
  }
}

class _EditionChip extends StatelessWidget {
  const _EditionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Semantics(
      button: true,
      label: '${BibleStrings.chooseVersion}, $label',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: LumSize.touchTarget),
          padding: const EdgeInsets.symmetric(horizontal: LumSpace.xl - 4),
          decoration: BoxDecoration(
            color: c.bgSurface,
            borderRadius: BorderRadius.circular(LumRadius.full),
            border: Border.all(color: c.borderSubtle),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LumText.headline.copyWith(color: c.textPrimary)),
              ),
              const SizedBox(width: LumSpace.xs),
              Icon(PhosphorIcons.caretDown(), size: 14, color: c.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// The big scrolling chapter title: optional eyebrow, then "John 15".
/// Tapping it opens the book and chapter pickers.
class ChapterTitle extends StatelessWidget {
  const ChapterTitle({
    super.key,
    required this.title,
    this.eyebrow,
    this.onTap,
  });

  final String title;
  final String? eyebrow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    final text = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(title,
          maxLines: 1,
          style: LumText.roadDisplayMedium56.copyWith(color: c.textPrimary)),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          LumSpace.sm, LumSpace.lg, LumSpace.sm, LumSpace.lg),
      child: Semantics(
        header: true,
        button: onTap != null,
        label: onTap == null ? title : '$title, ${BibleStrings.chooseChapter}',
        excludeSemantics: true,
        onTap: onTap,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: LumSize.touchTarget),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  Text(eyebrow!,
                      style: LumText.roadLabelCaps11
                          .copyWith(color: c.textSecondary)),
                  const SizedBox(height: LumSpace.xs),
                ],
                text,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
