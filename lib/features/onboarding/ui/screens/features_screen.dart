import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/features/onboarding/audio/onboarding_sfx.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/widgets/hand_drawn_button.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/widgets/typewriter_text.dart';

/// Third onboarding screen — describes what Abide is growing into: a place to
/// sing, study, take notes, and pray together as a family.
class FeaturesScreen extends HookWidget {
  const FeaturesScreen({super.key, required this.onNext, required this.sfx});

  final VoidCallback onNext;
  final OnboardingSfx sfx;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final scrollController = useScrollController();
    final showBody = useState(false);
    final showMore = useState(false);
    final showButton = useState(false);

    // Keep the latest typewriter line in view as the text grows.
    useEffect(() {
      final timer = Timer.periodic(const Duration(milliseconds: 120), (_) {
        if (!scrollController.hasClients) return;
        final max = scrollController.position.maxScrollExtent;
        if (scrollController.offset < max) {
          scrollController.animateTo(
            max,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
          );
        }
      });
      return timer.cancel;
    }, const []);

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 64),
                  TypewriterText(
                    text: 'a home for your faith.',
                    style: AppTextStyles.doodleHeadline(color: ink),
                    startDelay: const Duration(milliseconds: 300),
                    onTypingStart: sfx.penTickStart,
                    onComplete: () {
                      sfx.penTickStop();
                      showBody.value = true;
                    },
                  ),
                  const SizedBox(height: 24),
                  if (showBody.value)
                    TypewriterText(
                      text: 'sing the hymns you love,\n'
                          'with the words right in front of you.\n'
                          'read the Bible in your own tongue,\n'
                          'side by side with another, at your own pace.\n'
                          'and keep your notes in one quiet place.',
                      style: AppTextStyles.doodleBody(color: ink),
                      perCharacter: const Duration(milliseconds: 28),
                      onTypingStart: sfx.penTickStart,
                      onComplete: () {
                        sfx.penTickStop();
                        sfx.pageTurn();
                        showMore.value = true;
                      },
                    ),
                  const SizedBox(height: 20),
                  if (showMore.value)
                    TypewriterText(
                      text: 'and soon, pray together as a family,\n'
                          'morning and evening,\n'
                          'wherever each of you happens to be.',
                      style: AppTextStyles.doodleBody(color: ink),
                      perCharacter: const Duration(milliseconds: 28),
                      onTypingStart: sfx.penTickStart,
                      onComplete: () {
                        sfx.penTickStop();
                        sfx.revealWhoosh();
                        showButton.value = true;
                      },
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: AnimatedOpacity(
              opacity: showButton.value ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !showButton.value,
                child: HandDrawnButton(
                  label: 'continue',
                  onTap: () {
                    sfx.paperTap();
                    onNext();
                  },
                  startDelay: Duration.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
