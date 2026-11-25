import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/features/hymn/model/language_pack.dart';
import 'package:openbaptisthymnal/features/hymn/ui/hymn_strings.dart';
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
    this.languageLabel,
    this.meta,
    this.trailingHeader,
    this.bottomExtraSpace = 100,
    this.compact = false,
  });

  final HymnTranslation translation;
  final double textScale;
  final void Function(String body) onShare;
  final ScrollController? scrollController;

  /// Optional short label rendered near the title — e.g. "English" / "Yoruba"
  /// in split mode so the user always knows which pane is which.
  final String? languageLabel;

  /// The quiet line under the title, e.g. "4 stanzas · English".
  final String? meta;

  /// Optional widget rendered at the very top above the title (e.g. a close-X
  /// for the secondary pane).
  final Widget? trailingHeader;

  /// Extra space at the bottom so the floating bottom bar doesn't cover the
  /// last stanza. Set to 0 inside split mode if no bottom bar overlaps.
  final double bottomExtraSpace;

  /// Strip decorations for tight space (split-view panes): smaller title,
  /// no stanza numerals, tighter padding.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    final stanzas = translation.lyrics.stanzas;
    final chorus = translation.lyrics.chorus;
    final hasChorus = chorus != null && chorus.isNotEmpty;
    final totalCards = hasChorus ? stanzas.length + 1 : stanzas.length;
    final gutter = compact ? LumSpace.md : LumSize.screenGutter + 4;
    final eyebrow = languageLabel?.toUpperCase() ??
        HymnStrings.hymnEyebrow(translation.number);

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        if (trailingHeader != null) SliverToBoxAdapter(child: trailingHeader),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
              gutter, compact ? LumSpace.sm : LumSpace.lg, gutter, LumSpace.lg),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eyebrow,
                    style: LumText.roadLabelCaps11
                        .copyWith(color: c.textSecondary)),
                const SizedBox(height: LumSpace.xs),
                Semantics(
                  header: true,
                  child: Text(
                    translation.title,
                    style: (compact ? LumText.title3 : LumText.largeTitle)
                        .copyWith(color: c.textPrimary),
                  ),
                ),
                if (meta != null) ...[
                  const SizedBox(height: LumSpace.sm),
                  Text(meta!,
                      style:
                          LumText.subheadline.copyWith(color: c.textSecondary)),
                ],
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  _buildCardAt(index, stanzas, chorus, hasChorus),
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
