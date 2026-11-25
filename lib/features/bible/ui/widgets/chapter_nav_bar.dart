import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/widgets/lum_circle_button.dart';
import 'package:openbaptisthymnal/core/widgets/lum_glass_bar.dart';
import 'package:openbaptisthymnal/features/bible/ui/bible_strings.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Glass chapter nav (Figma `Chapter nav`): previous, "John 15  KJV", next.
/// Sits as a sibling of the scrolling text.
class ChapterNavBar extends StatelessWidget {
  const ChapterNavBar({
    super.key,
    required this.reference,
    required this.edition,
    required this.onPrev,
    required this.onNext,
    required this.onPick,
  });

  final String reference;
  final String edition;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return LumGlassBar(
      child: Row(
        children: [
          LumCircleButton(
            plain: true,
            icon: PhosphorIcons.caretLeft(),
            label: BibleStrings.previous,
            onPressed: onPrev,
            color: onPrev == null ? c.textDisabled : null,
          ),
          Expanded(
            child: Semantics(
              button: true,
              label: '$reference, ${BibleStrings.chooseChapter}',
              excludeSemantics: true,
              onTap: onPick,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onPick,
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(minHeight: LumSize.touchTarget),
                  child: Center(
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                            text: reference,
                            style: LumText.headline
                                .copyWith(color: c.textPrimary)),
                        TextSpan(
                            text: '  $edition',
                            style: LumText.footnote
                                .copyWith(color: c.textSecondary)),
                      ]),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          ),
          LumCircleButton(
            plain: true,
            icon: PhosphorIcons.caretRight(),
            label: BibleStrings.next,
            onPressed: onNext,
            color: onNext == null ? c.textDisabled : null,
          ),
        ],
      ),
    );
  }
}
