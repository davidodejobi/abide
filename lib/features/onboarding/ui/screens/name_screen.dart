import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/features/onboarding/audio/onboarding_sfx.dart';
import 'package:openbaptisthymnal/features/onboarding/providers/onboarding_provider.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/widgets/hand_drawn_button.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/widgets/hand_drawn_field.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/widgets/typewriter_text.dart';

/// Final onboarding screen — asks for the user's name, saves it, finishes.
class NameScreen extends HookConsumerWidget {
  const NameScreen({super.key, required this.onDone, required this.sfx});

  final VoidCallback onDone;
  final OnboardingSfx sfx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final controller = useTextEditingController();
    final showInput = useState(false);
    final submitting = useState(false);

    Future<void> finish() async {
      if (submitting.value) return;
      sfx.paperTap();
      submitting.value = true;
      ref.read(onboardingProvider.notifier).setName(controller.text);
      await ref.read(onboardingProvider.notifier).complete();
      onDone();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 3),
          TypewriterText(
            text: 'One last thing.\nWhat is your name?',
            style: AppTextStyles.doodleHeadline(color: ink),
            startDelay: const Duration(milliseconds: 300),
            onTypingStart: sfx.penTickStart,
            onComplete: () {
              sfx.penTickStop();
              sfx.revealWhoosh();
              showInput.value = true;
            },
          ),
          const SizedBox(height: 12),
          Text(
            'So Abide can feel like yours.',
            style: AppTextStyles.doodleBody(color: ink.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 32),
          if (showInput.value)
            AnimatedOpacity(
              opacity: showInput.value ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: HandDrawnField(
                controller: controller,
                hintText: 'Your name',
                onSubmitted: (_) => finish(),
              ),
            ),
          const Spacer(flex: 4),
          Center(
            child: AnimatedOpacity(
              opacity: showInput.value ? 1 : 0,
              duration: const Duration(milliseconds: 400),
              child: showInput.value
                  ? HandDrawnButton(
                      label: "Let's go",
                      onTap: finish,
                      startDelay: const Duration(milliseconds: 400),
                    )
                  : const SizedBox(height: 74),
            ),
          ),
        ],
      ),
    );
  }
}
