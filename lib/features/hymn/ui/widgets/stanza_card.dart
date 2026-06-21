import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/app_colors.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';

class StanzaCard extends StatelessWidget {
  final String text;
  final int displayIndex;
  final bool isChorus;

  /// Multiplier applied to the lyric body text only (the reader's font-size
  /// preference). The watermark number and card chrome stay fixed.
  final double textScale;

  /// Called with the text the user chose to share — the full stanza on a
  /// double-tap, or the highlighted selection from the "Share" toolbar action.
  final void Function(String text)? onShare;

  /// When true, strips the giant watermark number, tightens padding, and
  /// rounds less. Used by the split-view panes where space is tight.
  final bool compact;

  const StanzaCard({
    super.key,
    required this.text,
    required this.displayIndex,
    this.isChorus = false,
    this.textScale = 1.0,
    this.onShare,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine Colors
    Color cardBg;
    Color cardText;
    Color cardNumColor;

    if (isChorus) {
      // Chorus uses the brand primary color as the standout "main color"
      cardBg = isDark ? AppColors.primaryLight : AppColors.primary;
      cardText = AppColors.neutral100;
      cardNumColor = isDark
          ? AppColors.primaryDark
          : AppColors.primaryLight.withValues(alpha: 0.3);
    } else {
      // Other stanzas follow the "odd" styling as requested
      if (isDark) {
        cardBg = AppColors.neutral850;
        cardText = AppColors.neutral100;
        cardNumColor = AppColors.neutral700;
      } else {
        cardBg = AppColors.secondary50;
        cardText = AppColors.primaryDark;
        cardNumColor = AppColors.secondary100;
      }
    }

    final cardPadding = compact ? 12.0 : 16.0;
    final cardRadius = compact ? 16.0 : 32.0;
    final bottomGap = compact ? 8.0 : 16.0;
    final lyricRightInset = compact ? 8.0 : 40.0;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomGap),
      child: GestureDetector(
        // Double-tapping anywhere on the card shares the whole stanza. Taps on
        // the lyric text are handled by SelectableText's own double-tap below.
        onDoubleTap: onShare == null ? null : () => onShare!(text),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(cardRadius),
          border: isChorus
              ? Border.all(color: cardText.withValues(alpha: 0.2), width: 1)
              : null,
          boxShadow: compact
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Stack(
          children: [
            // Big Watermark Number/Label — hidden in compact (split) mode.
            if (!compact)
              Positioned(
                right: 0,
                top: -30,
                bottom: 0,
                child: Center(
                  child: Text(
                    isChorus ? 'C' : '$displayIndex',
                    style: AppTextStyles.displayLarge.copyWith(
                      fontSize: isChorus ? 64 : 98,
                      height: .7,
                      color: cardNumColor,
                    ),
                  ),
                ),
              ),
            // Text Content
            Padding(
              padding: EdgeInsets.only(right: lyricRightInset),
              child: SelectableText(
                text,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cardText,
                  fontStyle: isChorus ? FontStyle.italic : null,
                  fontSize: (AppTextStyles.bodyLarge.fontSize ?? 16) * textScale,
                ),
                textAlign: TextAlign.left,
                // Double-tapping a stanza shares the whole stanza.
                onSelectionChanged: (selection, cause) {
                  if (cause == SelectionChangedCause.doubleTap) {
                    onShare?.call(text);
                  }
                },
                contextMenuBuilder: onShare == null
                    ? null
                    : (context, editableTextState) {
                        final items = List<ContextMenuButtonItem>.of(
                          editableTextState.contextMenuButtonItems,
                        );
                        final value = editableTextState.textEditingValue;
                        final selection = value.selection;
                        final selected =
                            selection.isValid && !selection.isCollapsed
                                ? selection.textInside(value.text)
                                : value.text;
                        items.insert(
                          0,
                          ContextMenuButtonItem(
                            label: 'Share',
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
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
