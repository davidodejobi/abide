import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/features/hymn/ui/hymn_strings.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// The soft search pill (Figma Songs search). A clear button appears once
/// there is text.
class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({
    super.key,
    this.hintText = HymnStrings.searchHint,
    this.onChanged,
    this.controller,
  });

  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.only(left: LumSpace.lg),
      decoration: BoxDecoration(
        color: c.bgSurface,
        borderRadius: BorderRadius.circular(LumRadius.full),
        border: Border.all(color: c.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(PhosphorIcons.magnifyingGlass(),
              size: 22, color: c.iconSecondary),
          const SizedBox(width: LumSpace.md),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: LumText.body.copyWith(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: LumText.body.copyWith(color: c.textSecondary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: LumSpace.md),
                isDense: true,
              ),
            ),
          ),
          if (controller != null)
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller!,
              builder: (context, value, _) {
                if (value.text.isEmpty) {
                  return const SizedBox(width: LumSpace.lg);
                }
                return Padding(
                  padding: const EdgeInsets.only(right: LumSpace.sm),
                  child: Semantics(
                    button: true,
                    label: HymnStrings.clearSearch,
                    excludeSemantics: true,
                    onTap: () {
                      controller!.clear();
                      onChanged?.call('');
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        controller!.clear();
                        onChanged?.call('');
                      },
                      child: SizedBox(
                        width: LumSize.touchTarget,
                        height: LumSize.touchTarget,
                        child: Center(
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                                color: c.bgSurface, shape: BoxShape.circle),
                            child: Icon(PhosphorIcons.x(),
                                size: 16, color: c.textPrimary),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            )
          else
            const SizedBox(width: LumSpace.lg),
        ],
      ),
    );
  }
}
