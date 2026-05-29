import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/core/theme/font_scale.dart';
import 'package:openbaptisthymnal/core/theme/font_scale_provider.dart';

/// A snapping slider that steps through [FontScale] values, with a live preview
/// of lyric text at the selected size. Reused by the Settings selector and the
/// reading-screen bottom sheet so they stay in sync.
class FontSizeControl extends ConsumerWidget {
  const FontSizeControl({super.key, this.showPreview = true});

  /// Whether to render the sample-lyric preview above the slider.
  final bool showPreview;

  static const String _sampleLyric =
      'Amazing grace, how sweet the sound\nthat saved a wretch like me.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(fontScaleProvider);
    final colorScheme = Theme.of(context).colorScheme;
    const values = FontScale.values;
    final index = values.indexOf(scale);
    const baseSize = 16.0; // matches AppTextStyles.bodyLarge, the lyric base

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showPreview) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _sampleLyric,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
                fontSize: baseSize * scale.scale,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Text(
              'A',
              style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
            ),
            Expanded(
              child: Slider(
                value: index.toDouble(),
                min: 0,
                max: (values.length - 1).toDouble(),
                divisions: values.length - 1,
                label: scale.label,
                activeColor: colorScheme.primary,
                onChanged: (v) => ref
                    .read(fontScaleProvider.notifier)
                    .setScale(values[v.round()]),
              ),
            ),
            Text(
              'A',
              style: TextStyle(fontSize: 24, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        Center(
          child: Text(
            scale.label,
            style: AppTextStyles.labelLarge.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
