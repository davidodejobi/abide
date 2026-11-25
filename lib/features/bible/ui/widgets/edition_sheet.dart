import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/widgets/lum_circle_button.dart';
import 'package:openbaptisthymnal/core/widgets/lum_group_card.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_edition.dart';
import 'package:openbaptisthymnal/features/bible/ui/bible_strings.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Bible version sheet (Figma 04). Lists only the editions the app ships; they
/// are all on the phone already, so there is no download or Plus row. Returns
/// the chosen edition id.
Future<String?> showEditionSheet(
  BuildContext context, {
  required List<BibleEdition> editions,
  required String currentId,
}) {
  final c = context.lum;
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: c.bgElevated,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    builder: (_) => EditionSheet(editions: editions, currentId: currentId),
  );
}

class EditionSheet extends StatelessWidget {
  const EditionSheet(
      {super.key, required this.editions, required this.currentId});

  final List<BibleEdition> editions;
  final String currentId;

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
