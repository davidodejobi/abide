import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/features/onboarding/audio/onboarding_sfx.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/widgets/hand_drawn_button.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/widgets/typewriter_text.dart';

/// First onboarding screen — types a short welcome, then a hand-drawn button.
class WelcomeScreen extends HookWidget {
  const WelcomeScreen({super.key, required this.onNext, required this.sfx});

  final VoidCallback onNext;
  final OnboardingSfx sfx;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final showLine2 = useState(false);
    final showButton = useState(false);

    // Soft warm bell as the screen enters, just before typing starts.
    useEffect(() {
      final timer = Future.delayed(
        const Duration(milliseconds: 200),
        sfx.welcomeChime,
      );
      return () {
        timer.ignore();
      };
    }, const []);

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 3),
          TypewriterText(
            text: 'kaabo. welcome to abide.',
            style: AppTextStyles.doodleHeadline(color: ink),
            startDelay: const Duration(milliseconds: 350),
            onTypingStart: sfx.penTickStart,
            onComplete: () {
              sfx.penTickStop();
              showLine2.value = true;
            },
          ),
          const SizedBox(height: 18),
          if (showLine2.value)
            TypewriterText(
              text: 'a quiet corner for your faith —\n'
                  'a place to sing, to study,\n'
                  'to write, and to abide.\n'
                  'with you, morning and evening.',
              style: AppTextStyles.doodleBody(color: ink),
              perCharacter: const Duration(milliseconds: 30),
              startDelay: const Duration(milliseconds: 250),
              onTypingStart: sfx.penTickStart,
              onComplete: () {
                sfx.penTickStop();
                sfx.revealWhoosh();
                showButton.value = true;
              },
            ),
          const Spacer(flex: 4),
          Center(
            child: AnimatedOpacity(
              opacity: showButton.value ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: showButton.value
                  ? HandDrawnButton(
                      label: 'begin',
                      onTap: () {
                        sfx.paperTap();
                        onNext();
                      },
                      startDelay: const Duration(milliseconds: 150),
                    )
                  : const SizedBox(height: 74),
            ),
          ),
        ],
      ),
    );
  }
}
