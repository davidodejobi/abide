import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/theme/font_scale.dart';
import 'package:openbaptisthymnal/core/theme/font_scale_provider.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/features/settings/ui/you_strings.dart';

/// A snapping slider that steps through [FontScale] values, with a live preview
/// of lyric text at the selected size. Reused by the You tab and the
/// reading-screen bottom sheet so they stay in sync.
class FontSizeControl extends ConsumerWidget {
  const FontSizeControl({super.key, this.showPreview = true});

  /// Whether to render the sample-lyric preview above the slider.
  final bool showPreview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lum;
    final scale = ref.watch(fontScaleProvider);
    const values = FontScale.values;
    final index = values.indexOf(scale);
    const baseSize = 17.0; // readingLyricsCompact, the lyric base

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showPreview) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(LumSpace.lg),
            decoration: BoxDecoration(
              color: c.bgSurfaceSunken,
              borderRadius: BorderRadius.circular(LumRadius.lg),
            ),
            child: Text(
              YouStrings.fontSizeSample,
              style: LumText.readingLyricsCompact.copyWith(
                color: c.textPrimary,
                fontSize: baseSize * scale.scale,
              ),
            ),
          ),
          const SizedBox(height: LumSpace.sm),
        ],
        Row(
          children: [
            Text('A', style: LumText.footnote.copyWith(color: c.textSecondary)),
            Expanded(
              child: Slider(
                value: index.toDouble(),
                min: 0,
                max: (values.length - 1).toDouble(),
                divisions: values.length - 1,
                label: scale.label,
                semanticFormatterCallback: (_) => scale.label,
                activeColor: c.bgPrimary,
                onChanged: (v) => ref
                    .read(fontScaleProvider.notifier)
                    .setScale(values[v.round()]),
              ),
            ),
            Text('A', style: LumText.title2.copyWith(color: c.textSecondary)),
          ],
        ),
        Center(
          child: Text(
            scale.label,
            style: LumText.subheadlineEmphasized.copyWith(color: c.textPrimary),
          ),
        ),
      ],
    );
  }
}
