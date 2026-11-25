import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/features/hymn/ui/hymn_strings.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// One hymn row (Figma Songs list): a gold-tint number badge, the title, the
/// first line, and an optional heart. Rows sit inside a [LumGroupCard], so the
/// tile draws only its own hairline.
class HymnListTile extends StatelessWidget {
  const HymnListTile({
    super.key,
    required this.number,
    required this.title,
    this.subtitle,
    this.onTap,
    this.isFavorited = false,
    this.onToggleFavorite,
    this.showDivider = true,
    this.borderRadius,
  });

  final String number;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isFavorited;

  /// When set the row shows a tappable heart; otherwise a filled heart appears
  /// only if [isFavorited].
  final VoidCallback? onToggleFavorite;
  final bool showDivider;

  /// Keeps the press highlight inside the group card's rounded corners.
  final BorderRadius? borderRadius;

  /// The corner radius for row [index] of [count] inside a [LumGroupCard].
  static BorderRadius edgeRadius(int index, int count) {
    const r = Radius.circular(LumRadius.xl);
    return BorderRadius.vertical(
      top: index == 0 ? r : Radius.zero,
      bottom: index == count - 1 ? r : Radius.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    final heartColor = isFavorited ? c.textPrimary : c.textSecondary;
    final label = [
      'Hymn $number',
      title,
      if (isFavorited) 'favourite',
    ].join(', ');
    final content = Padding(
      padding: const EdgeInsets.only(left: LumSpace.lg),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: c.bgAccentContainer,
              borderRadius: BorderRadius.circular(LumRadius.md),
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(LumSpace.xs),
                child: Text(
                  number,
                  textScaler: TextScaler.noScaling,
                  style: LumText.roadDisplayStat28
                      .copyWith(fontSize: 22, color: c.textOnAccentContainer),
                ),
              ),
            ),
          ),
          const SizedBox(width: LumSpace.lg),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: LumSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: LumText.headline.copyWith(color: c.textPrimary)),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            LumText.footnote.copyWith(color: c.textSecondary)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // The heart is its own control beside the row, so it keeps its own label
    // for screen readers and never triggers the row.
    final Widget trailing;
    if (onToggleFavorite != null) {
      trailing = Semantics(
        button: true,
        label: isFavorited
            ? HymnStrings.removeFavourite
            : HymnStrings.addFavourite,
        excludeSemantics: true,
        onTap: onToggleFavorite,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onToggleFavorite,
          child: SizedBox(
            width: LumSize.touchTarget + 4,
            height: LumSize.touchTarget + 8,
            child: Icon(
              isFavorited
                  ? PhosphorIcons.heart(PhosphorIconsStyle.fill)
                  : PhosphorIcons.heart(),
              size: LumSize.iconMd,
              color: heartColor,
            ),
          ),
        ),
      );
    } else if (isFavorited) {
      trailing = Padding(
        padding: const EdgeInsets.symmetric(horizontal: LumSpace.lg),
        child: Icon(PhosphorIcons.heart(PhosphorIconsStyle.fill),
            size: 18, color: heartColor),
      );
    } else {
      trailing = const SizedBox(width: LumSpace.lg);
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: c.borderSubtle))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: label,
              excludeSemantics: true,
              onTap: onTap,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: borderRadius,
                  onTap: onTap,
                  child: content,
                ),
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
