import 'package:material_ui/material_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/widgets/lum_button.dart';
import 'package:openbaptisthymnal/features/plus/data/purchase_service.dart';
import 'package:openbaptisthymnal/features/plus/plus_config.dart';
import 'package:openbaptisthymnal/features/plus/providers/plus_providers.dart';

/// Last onboarding screen: one optional trial card, with "Continue free" the
/// same size as the offer. Onboarding is already saved by the time this shows.
class PlusOfferScreen extends HookConsumerWidget {
  const PlusOfferScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lum;
    final busy = useState(false);

    Future<void> start() async {
      if (busy.value) return;
      busy.value = true;
      await ref.read(plusProvider.notifier).startTrial(PlusPlan.annual);
      if (!context.mounted) return;
      busy.value = false;
      onDone();
    }

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
                  label: PlusStrings.startTrial,
                  kind: LumButtonKind.gold,
                  onPressed: busy.value ? null : start,
                ),
                const SizedBox(height: LumSpace.md),
                LumButton(
                  label: PlusStrings.continueFree,
                  kind: LumButtonKind.secondary,
                  onPressed: busy.value ? null : onDone,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
