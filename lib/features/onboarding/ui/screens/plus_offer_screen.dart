import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/widgets/lum_button.dart';
import 'package:openbaptisthymnal/features/plus/plus_config.dart';

/// Last onboarding screen: one optional trial card, with "Continue free" the
/// same size as the offer. Onboarding is already saved by the time this shows.
class PlusOfferScreen extends StatelessWidget {
  const PlusOfferScreen(
      {super.key, required this.onDone, required this.onSeePlans});
  final VoidCallback onDone;

  /// Opens the Plus screen (plans, terms, privacy) after onboarding.
  final VoidCallback onSeePlans;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Padding(
            padding: const EdgeInsets.all(LumSpace.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(PlusStrings.onboardingTitle,
                      style: LumText.title1.copyWith(color: c.textPrimary)),
                ),
                const SizedBox(height: LumSpace.md),
                Text(PlusStrings.onboardingBody,
                    style: LumText.body.copyWith(color: c.textSecondary)),
                const SizedBox(height: LumSpace.sm),
                Text(PlusStrings.thenPrice(PlusConfig.annualPrice, 'year'),
                    style: LumText.footnote.copyWith(color: c.textSecondary)),
                const SizedBox(height: LumSpace.xl),
                LumButton(
                  label: PlusStrings.seePlans,
                  kind: LumButtonKind.gold,
                  onPressed: onSeePlans,
                ),
                const SizedBox(height: LumSpace.md),
                LumButton(
                  label: PlusStrings.continueFree,
                  kind: LumButtonKind.secondary,
                  onPressed: onDone,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
