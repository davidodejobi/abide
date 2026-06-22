import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/core/utils/time_greeting.dart';
import 'package:openbaptisthymnal/features/onboarding/audio/onboarding_sfx.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/widgets/hand_drawn_button.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/widgets/hand_drawn_moon.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/widgets/hand_drawn_sun.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/widgets/typewriter_text.dart';

/// First onboarding screen — types the welcome greeting, draws a sun or moon
/// based on the time of day, types a time-based greeting with a short
/// devotional line, then shows a "continue" button.
class WelcomeSceneScreen extends HookWidget {
  const WelcomeSceneScreen({
    super.key,
    required this.onNext,
    required this.sfx,
    this.now,
  });

  final VoidCallback onNext;
  final OnboardingSfx sfx;

  /// Injectable clock for testing; defaults to [DateTime.now] at build time.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final copy = useMemoized(
      () => _SceneCopy.forHour((now ?? DateTime.now()).hour),
      [now],
    );
    final showScene = useState(false);
    final showText = useState(false);
    final showButton = useState(false);

    useEffect(() {
      final timer = Future.delayed(
        const Duration(milliseconds: 200),
        sfx.welcomeChime,
      );
      return () {
        timer.ignore();
      };
    }, const []);

    useEffect(() {
      return sfx.pencilDrawStop;
    }, [copy]);

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 2),
          TypewriterText(
            text: 'Kaabo. Welcome to Abide.',
            style: AppTextStyles.doodleHeadline(color: ink),
            startDelay: const Duration(milliseconds: 350),
            onTypingStart: sfx.penTickStart,
            onComplete: () {
              sfx.penTickStop();
              sfx.pencilDrawStart();
              sfx.revealWhoosh();
              showScene.value = true;
              Future.delayed(const Duration(milliseconds: 1600), () {
                sfx.pencilDrawStop();
                if (copy.isNight) {
                  sfx.nightBloom();
                } else {
                  sfx.dayBloom();
                }
                showText.value = true;
              });
            },
          ),
          if (showScene.value) ...[
            const SizedBox(height: 28),
            Center(
              child: copy.isNight
                  ? const HandDrawnMoon(startDelay: Duration.zero)
                  : const HandDrawnSun(startDelay: Duration.zero),
            ),
            const SizedBox(height: 28),
            if (showText.value) ...[
              TypewriterText(
                text: copy.headline,
                style: AppTextStyles.doodleHeadline(color: ink),
                onTypingStart: sfx.penTickStart,
                onComplete: sfx.penTickStop,
              ),
              const SizedBox(height: 16),
              TypewriterText(
                text: copy.body,
                style: AppTextStyles.doodleBody(color: ink),
                perCharacter: const Duration(milliseconds: 30),
                startDelay: const Duration(milliseconds: 900),
                onTypingStart: sfx.penTickStart,
                onComplete: () {
                  sfx.penTickStop();
                  showButton.value = true;
                },
              ),
            ],
          ],
          const Spacer(flex: 2),
          Center(
            child: AnimatedOpacity(
              opacity: showButton.value ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: showButton.value
                  ? HandDrawnButton(
                      label: 'Continue',
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

/// Greeting + devotional copy and which celestial body to draw, by hour.
class _SceneCopy {
  const _SceneCopy({
    required this.headline,
    required this.body,
    required this.isNight,
  });

  final String headline;
  final String body;
  final bool isNight;

  factory _SceneCopy.forHour(int hour) {
    final part = TimeGreeting.forHour(hour).part;
    switch (part) {
      case DayPart.morning:
        return const _SceneCopy(
          isNight: false,
          headline: 'Good morning.',
          body: 'The Word is waiting for you.\n'
              'Start your day with a passage that speaks.',
        );
      case DayPart.afternoon:
        return const _SceneCopy(
          isNight: false,
          headline: 'Good afternoon.',
          body: 'Your spirit needs lifting.\n'
              'A familiar hymn can find you where you are.',
        );
      case DayPart.evening:
        return const _SceneCopy(
          isNight: true,
          headline: 'Good evening.',
          body: 'The day has taught you something.\n'
              'Take a moment to write it down.',
        );
      case DayPart.night:
        return const _SceneCopy(
          isNight: true,
          headline: 'Abide in Christ.',
          body: 'The hours are still.\n'
              'Rest in the vine.',
        );
    }
  }
}
