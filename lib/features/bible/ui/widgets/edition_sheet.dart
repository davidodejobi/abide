import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/widgets/lum_circle_button.dart';
import 'package:openbaptisthymnal/core/widgets/lum_group_card.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_edition.dart';
import 'package:openbaptisthymnal/features/bible/ui/bible_strings.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Returned by [showEditionSheet] when the user taps "Get more Bibles".
const kGetMoreBibles = '__get_more_bibles__';

/// Bible version sheet (Figma 04). Lists the editions on the phone (bundled and
/// downloaded) with a "Get more Bibles" row at the end when [canGetMore].
/// Returns the chosen edition id, or [kGetMoreBibles].
Future<String?> showEditionSheet(
  BuildContext context, {
  required List<BibleEdition> editions,
  required String currentId,
  bool canGetMore = false,
}) {
  final c = context.lum;
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: c.bgElevated,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    builder: (_) => EditionSheet(
        editions: editions, currentId: currentId, canGetMore: canGetMore),
  );
}

class EditionSheet extends StatelessWidget {
  const EditionSheet({
    super.key,
    required this.editions,
    required this.currentId,
    this.canGetMore = false,
  });

  final List<BibleEdition> editions;
  final String currentId;
  final bool canGetMore;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(LumSize.screenGutter, LumSpace.md,
            LumSize.screenGutter, LumSpace.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: c.borderStrong,
                  borderRadius: BorderRadius.circular(LumRadius.full),
                ),
              ),
            ),
            const SizedBox(height: LumSpace.md),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(BibleStrings.bibleVersion,
                        style: LumText.title1.copyWith(color: c.textPrimary)),
                  ),
                ),
                LumCircleButton(
                  icon: PhosphorIcons.x(),
                  label: BibleStrings.close,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: LumSpace.lg),
            Text(BibleStrings.onThisPhone,
                style:
                    LumText.roadLabelCaps11.copyWith(color: c.textSecondary)),
            const SizedBox(height: LumSpace.sm),
            LumGroupCard(
              child: Column(
                children: [
                  for (var i = 0; i < editions.length; i++)
                    _EditionRow(
                      edition: editions[i],
                      inUse: editions[i].id == currentId,
                      divider: i < editions.length - 1,
                      onTap: () => Navigator.of(context).pop(editions[i].id),
                    ),
                  if (canGetMore)
                    _GetMoreRow(
                        onTap: () =>
                            Navigator.of(context).pop(kGetMoreBibles)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditionRow extends StatelessWidget {
  const _EditionRow({
    required this.edition,
    required this.inUse,
    required this.divider,
    required this.onTap,
  });

  final BibleEdition edition;
  final bool inUse;
  final bool divider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Semantics(
      button: true,
      selected: inUse,
      label: '${edition.displayName}, ${edition.attribution}'
          '${inUse ? ', ${BibleStrings.inUse}' : ''}',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: LumSize.rowMin),
          padding: const EdgeInsets.symmetric(
              horizontal: LumSpace.lg, vertical: LumSpace.md),
          decoration: BoxDecoration(
            border: divider
                ? Border(bottom: BorderSide(color: c.borderSubtle))
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(edition.displayName,
                        style: LumText.bodyEmphasized
                            .copyWith(color: c.textPrimary)),
                    const SizedBox(height: 2),
                    Text(edition.attribution,
                        style:
                            LumText.footnote.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
              if (inUse) ...[
                const SizedBox(width: LumSpace.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: LumSpace.md, vertical: LumSpace.xs + 2),
                  decoration: BoxDecoration(
                    color: c.bgPrimary,
                    borderRadius: BorderRadius.circular(LumRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded,
                          size: 16, color: c.textOnPrimary),
                      const SizedBox(width: 4),
                      Text(BibleStrings.inUse,
                          style: LumText.footnoteEmphasized
                              .copyWith(color: c.textOnPrimary)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GetMoreRow extends StatelessWidget {
  const _GetMoreRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Semantics(
      button: true,
      label: BibleStrings.getMoreBibles,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: LumSize.rowMin),
          padding: const EdgeInsets.symmetric(
              horizontal: LumSpace.lg, vertical: LumSpace.md),
          decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.borderSubtle))),
          child: Row(
            children: [
              Icon(PhosphorIcons.downloadSimple(),
                  size: LumSize.iconMd, color: c.iconDefault),
              const SizedBox(width: LumSpace.md),
              Expanded(
                child: Text(BibleStrings.getMoreBibles,
                    style:
                        LumText.bodyEmphasized.copyWith(color: c.textPrimary)),
              ),
              Icon(PhosphorIcons.caretRight(),
                  size: LumSize.iconSm, color: c.iconSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
