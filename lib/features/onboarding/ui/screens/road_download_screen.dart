import 'package:material_ui/material_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/features/daily/providers/landmark_download_provider.dart';
import 'package:openbaptisthymnal/features/daily/ui/widgets/road_parade.dart';

import '../onboarding_strings.dart';
import '../widgets/onboarding_frame.dart';

/// Step 3: offer the 3D landmark download. "Download now" starts it in the
/// background and moves on at once; "Later" just remembers the answer.
class RoadDownloadScreen extends ConsumerWidget {
  const RoadDownloadScreen({
    super.key,
    required this.step,
    required this.total,
    required this.onNext,
    required this.onBack,
  });

  final int step;
  final int total;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lum;
    final bytes = ref.watch(remoteLandmarkModelsProvider).maybeWhen(
          data: (m) => m.fold<int>(0, (a, e) => a + e.bytes),
          orElse: () => 0,
        );
    final notifier = ref.read(landmarkDownloadProvider.notifier);
    return OnboardingFrame(
      step: step,
      totalSteps: total,
      onBack: onBack,
      primaryLabel: OnboardingStrings.downloadNow,
      onPrimary: () {
        // Not awaited: the download runs on while onboarding continues.
        notifier.start();
        onNext();
      },
      secondaryLabel: OnboardingStrings.later,
      onSecondary: () {
        notifier.decline();
        onNext();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RoadAheadHero(height: 150),
          const SizedBox(height: LumSpace.md),
          Semantics(
            header: true,
            child: Text(OnboardingStrings.roadTitle,
                style: LumText.title1.copyWith(color: c.textPrimary)),
          ),
          const SizedBox(height: LumSpace.md),
          Text(OnboardingStrings.roadBody,
              style: LumText.body.copyWith(color: c.textSecondary)),
          const SizedBox(height: LumSpace.md),
          Text(
              bytes == 0
                  ? OnboardingStrings.roadSizeUnknown
                  : OnboardingStrings.roadSize(landmarkSizeLabel(bytes)),
              style: LumText.footnote.copyWith(color: c.textSecondary)),
        ],
      ),
    );
  }
}
