import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/features/hymn/ui/hymn_strings.dart';

/// One stanza (or the chorus) in the reading style: a gold numeral beside the
/// lyric on the calm page, with no card or art behind it.
class StanzaCard extends StatelessWidget {
  const StanzaCard({
    super.key,
    required this.text,
    required this.displayIndex,
    this.isChorus = false,
    this.textScale = 1.0,
    this.onShare,
    this.compact = false,
  });

  final String text;
  final int displayIndex;
  final bool isChorus;

  /// Multiplier applied to the lyric text only (the reader's font-size
  /// preference). The numeral stays fixed.
  final double textScale;

  /// Called with the text the user chose to share: the full stanza on a
  /// double-tap, or the highlighted selection from the "Share" toolbar action.
  final void Function(String text)? onShare;

  /// Tighter spacing and the compact lyric size for split-view panes.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    final base = compact ? LumText.readingLyricsCompact : LumText.readingLyrics;
    final lyric = base.copyWith(
      fontSize: base.fontSize! * textScale,
      color: c.textPrimary,
      fontStyle: isChorus ? FontStyle.italic : null,
    );
    final numeral = LumText.roadDisplayStat28.copyWith(
      fontSize: compact ? 20 : 24,
      color: c.textAccent,
    );
    final gutter = compact ? 0.0 : 36.0;

    final body = SelectableText(
      text,
      style: lyric,
      textAlign: TextAlign.left,
      // Double-tapping a stanza shares the whole stanza.
      onSelectionChanged: (selection, cause) {
        if (cause == SelectionChangedCause.doubleTap) onShare?.call(text);
      },
      contextMenuBuilder: onShare == null
          ? null
          : (context, editableTextState) {
              final items = List<ContextMenuButtonItem>.of(
                editableTextState.contextMenuButtonItems,
              );
              final value = editableTextState.textEditingValue;
              final selection = value.selection;
              final selected = selection.isValid && !selection.isCollapsed
                  ? selection.textInside(value.text)
                  : value.text;
              items.insert(
                0,
                ContextMenuButtonItem(
                  label: HymnStrings.share,
                  onPressed: () {
                    editableTextState.hideToolbar();
                    onShare?.call(selected);
                  },
                ),
              );
              return AdaptiveTextSelectionToolbar.buttonItems(
                anchors: editableTextState.contextMenuAnchors,
                buttonItems: items,
              );
            },
    );

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? LumSpace.md : LumSpace.xl),
      child: GestureDetector(
        // Double-tapping anywhere on the stanza shares it. Taps on the lyric
        // text are handled by SelectableText's own double-tap above.
        onDoubleTap: onShare == null ? null : () => onShare!(text),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isChorus)
              Padding(
                padding: EdgeInsets.only(left: gutter, bottom: LumSpace.xs),
                child: Text(HymnStrings.chorus,
                    style:
                        LumText.roadLabelCaps11.copyWith(color: c.textAccent)),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!compact)
                  SizedBox(
                    width: gutter,
                    child: isChorus
                        ? null
                        : Text('$displayIndex',
                            textScaler: TextScaler.noScaling, style: numeral),
                  ),
                Expanded(child: body),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
