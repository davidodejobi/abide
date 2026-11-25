import 'package:material_ui/material_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';

import '../../providers/onboarding_provider.dart';
import '../onboarding_strings.dart';
import '../widgets/onboarding_frame.dart';

/// Step 3: first name (optional), then save everything and finish.
class NameScreen extends HookConsumerWidget {
  const NameScreen({
    super.key,
    required this.step,
    required this.total,
    required this.onDone,
    required this.onBack,
  });

  final int step;
  final int total;
  final VoidCallback onDone;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lum;
    final controller =
        useTextEditingController(text: ref.read(onboardingProvider).name);
    final saving = ref.watch(onboardingProvider.select((s) => s.saving));
    final failed = useState(false);

    Future<void> finish() async {
      if (saving) return;
      failed.value = false;
      final notifier = ref.read(onboardingProvider.notifier);
      notifier.setName(controller.text);
      try {
        await notifier.complete();
        onDone();
      } catch (_) {
        if (context.mounted) failed.value = true;
      }
    }

    return OnboardingFrame(
      step: step,
      totalSteps: total,
      onBack: saving ? null : onBack,
      primaryLabel: OnboardingStrings.startRoad,
      onPrimary: saving ? null : finish,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(OnboardingStrings.nameTitle,
                style: LumText.title1.copyWith(color: c.textPrimary)),
          ),
          const SizedBox(height: LumSpace.xl),
          Text(OnboardingStrings.nameLabelCaps,
              style: LumText.roadLabelCaps11.copyWith(color: c.textSecondary)),
          const SizedBox(height: LumSpace.sm),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.givenName],
            onChanged: ref.read(onboardingProvider.notifier).setName,
            onSubmitted: (_) => finish(),
            style: LumText.body.copyWith(color: c.textPrimary),
            cursorColor: c.buttonGoldBottom,
            decoration: InputDecoration(
              hintText: OnboardingStrings.nameHint,
              hintStyle: LumText.body.copyWith(color: c.textSecondary),
              filled: true,
              fillColor: c.bgSurface,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: LumSpace.lg, vertical: LumSpace.lg),
              border: _border(c.borderSubtle),
              enabledBorder: _border(c.borderSubtle),
              focusedBorder: _border(c.borderFocus, width: 2),
            ),
          ),
          const SizedBox(height: LumSpace.sm),
          Text(OnboardingStrings.nameHelp,
              style: LumText.footnote.copyWith(color: c.textSecondary)),
          if (failed.value) ...[
            const SizedBox(height: LumSpace.md),
            Semantics(
              liveRegion: true,
              child: Text(OnboardingStrings.finishError,
                  style: LumText.footnote.copyWith(color: c.textDanger)),
            ),
          ],
        ],
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(LumRadius.lg),
        borderSide: BorderSide(color: color, width: width),
      );
}
