import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';

import '../onboarding_strings.dart';
import '../widgets/onboarding_frame.dart';

/// Step zero: the road, one line about the app, and "Begin".
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return OnboardingFrame(
      primaryLabel: OnboardingStrings.begin,
      onPrimary: onNext,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(OnboardingStrings.freeAlwaysCaps,
              style: LumText.roadLabelCaps11.copyWith(color: c.textSecondary)),
          const SizedBox(height: LumSpace.md),
          Semantics(
            header: true,
            child: Text(OnboardingStrings.welcomeTitle,
                style: LumText.title1.copyWith(color: c.textPrimary)),
          ),
          const SizedBox(height: LumSpace.md),
          Text(OnboardingStrings.welcomeBody,
              style: LumText.body.copyWith(color: c.textSecondary)),
        ],
      ),
    );
  }
}
