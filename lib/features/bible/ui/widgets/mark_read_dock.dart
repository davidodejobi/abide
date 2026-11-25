import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/widgets/lum_button.dart';
import 'package:openbaptisthymnal/core/widgets/lum_circle_button.dart';
import 'package:openbaptisthymnal/features/bible/ui/bible_strings.dart';
import 'package:openbaptisthymnal/features/daily/ui/widgets/lamp_icon.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// The docked panel under the text when the reader was opened from a plan day
/// (Figma 02): the streak line and the gold "Mark read". A sibling of the
/// scrolling text, with no art behind Scripture.
class MarkReadDock extends StatelessWidget {
  const MarkReadDock({
    super.key,
    required this.streakLine,
    required this.onMarkRead,
    this.onPrev,
    this.onNext,
  });

  /// Previous / next chapter; null disables the button.
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  /// "Lights day 12 of your streak"; null hides the line.
  final String? streakLine;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.scenePanel,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
              color: c.sceneShadow,
              blurRadius: 28,
              offset: const Offset(0, -8)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          LumSize.screenGutter,
          LumSpace.lg,
          LumSize.screenGutter,
          LumSpace.lg + MediaQuery.paddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (streakLine != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const LampIcon(size: 20),
                const SizedBox(width: LumSpace.sm),
                Flexible(
                  child: Text(streakLine!,
                      textAlign: TextAlign.center,
                      style: LumText.footnote.copyWith(color: c.textSecondary)),
                ),
              ],
            ),
            const SizedBox(height: LumSpace.md),
          ],
          Row(
            children: [
              LumCircleButton(
                icon: PhosphorIcons.caretLeft(),
                label: BibleStrings.previous,
                onPressed: onPrev,
                color: onPrev == null ? c.textDisabled : null,
              ),
              const SizedBox(width: LumSpace.sm),
              Expanded(
                child: LumButton(
                  label: BibleStrings.markRead,
                  kind: LumButtonKind.gold,
                  icon: const Icon(Icons.check_rounded),
                  onPressed: onMarkRead,
                ),
              ),
              const SizedBox(width: LumSpace.sm),
              LumCircleButton(
                icon: PhosphorIcons.caretRight(),
                label: BibleStrings.next,
                onPressed: onNext,
                color: onNext == null ? c.textDisabled : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
