import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/app_colors.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/features/hymn/model/language_pack.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/stanza_card.dart';

/// Renders a single hymn translation (title + stanzas + optional chorus) as a
/// scrollable column. Designed to be embedded as either a full page or a pane
/// inside [SplitPane].
///
/// Provide a [scrollController] when the embedder wants to observe or drive the
/// scroll position (used for anchor-based sync in split mode).
class HymnView extends StatelessWidget {
  const HymnView({
    super.key,
    required this.translation,
    required this.textScale,
    required this.onShare,
    this.scrollController,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    this.languageLabel,
    this.trailingHeader,
    this.bottomExtraSpace = 100,
    this.titleRightInset = 0,
    this.compact = false,
  });

  final HymnTranslation translation;
  final double textScale;
  final void Function(String body) onShare;
  final ScrollController? scrollController;
  final EdgeInsetsGeometry padding;

  /// Optional short label rendered near the title — e.g. "English" / "Yoruba"
  /// in split mode so the user always knows which pane is which.
  final String? languageLabel;

  /// Optional widget rendered at the very top above the title (e.g. a close-X
  /// for the secondary pane).
  final Widget? trailingHeader;

  /// Extra space at the bottom so the floating bottom bar doesn't cover the
  /// last stanza. Set to 0 inside split mode if no bottom bar overlaps.
  final double bottomExtraSpace;

  /// Extra right padding on the title block so a parent watermark (e.g. the
  /// big "003") doesn't collide with long titles. Only used in single-pane.
  final double titleRightInset;

  /// Strip decorations for tight space (split-view panes): smaller title,
  /// flat stanza cards with no big watermark numbers, tighter padding.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.neutral100 : AppColors.neutral700;
    final labelColor = isDark ? AppColors.neutral500 : AppColors.neutral500;

    final stanzas = translation.lyrics.stanzas;
    final chorus = translation.lyrics.chorus;
    final hasChorus = chorus != null && chorus.isNotEmpty;
    final totalCards = hasChorus ? stanzas.length + 1 : stanzas.length;

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        if (trailingHeader != null)
          SliverToBoxAdapter(child: trailingHeader),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            padding.horizontal / 2,
            padding.vertical / 2,
            (padding.horizontal / 2) + titleRightInset,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (languageLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      languageLabel!.toUpperCase(),
                      style: AppTextStyles.bodySmall.copyWith(
                        letterSpacing: 1.2,
                        color: labelColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Text(
                  translation.title,
                  style: (compact
                          ? AppTextStyles.titleMedium
                          : AppTextStyles.headlineLarge)
                      .copyWith(
                    fontWeight: FontWeight.w600,
                    color: primaryTextColor,
                  ),
                  maxLines: compact ? 2 : null,
                  overflow:
                      compact ? TextOverflow.ellipsis : TextOverflow.visible,
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: padding,
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildCardAt(index, stanzas, chorus, hasChorus),
              childCount: totalCards,
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: bottomExtraSpace)),
      ],
    );
  }

  Widget? _buildCardAt(
    int index,
    List stanzas,
    String? chorus,
    bool hasChorus,
  ) {
    if (hasChorus) {
      if (index == 0) {
        return StanzaCard(
          text: stanzas[0].text,
          displayIndex: 1,
          textScale: textScale,
          onShare: onShare,
          compact: compact,
        );
      }
      if (index == 1) {
        return StanzaCard(
          text: chorus!,
          displayIndex: 0,
          isChorus: true,
          textScale: textScale,
          onShare: onShare,
          compact: compact,
        );
      }
      final stanzaIndex = index - 1;
      if (stanzaIndex < stanzas.length) {
        return StanzaCard(
          text: stanzas[stanzaIndex].text,
          displayIndex: index,
          textScale: textScale,
          onShare: onShare,
          compact: compact,
        );
      }
      return null;
    }
    if (index < stanzas.length) {
      return StanzaCard(
        text: stanzas[index].text,
        displayIndex: index + 1,
        textScale: textScale,
        onShare: onShare,
        compact: compact,
      );
    }
    return null;
  }
}
