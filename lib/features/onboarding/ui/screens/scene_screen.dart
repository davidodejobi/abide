import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/core/utils/time_greeting.dart';
import 'package:openbaptisthymnal/features/onboarding/audio/onboarding_sfx.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/widgets/hand_drawn_button.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/widgets/hand_drawn_moon.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/widgets/hand_drawn_sun.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/widgets/typewriter_text.dart';

/// Second onboarding screen — a sun (day) or moon (evening/night) draws itself
/// based on the current time, then a greeting + devotional line type out.
class SceneScreen extends HookWidget {
  const SceneScreen({
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
    final showText = useState(false);
    final showButton = useState(false);

    // Pencil scratch under the celestial body's stroke (aligned with its
    // 300ms startDelay), then a day/night bloom + reveal text on completion.
    useEffect(() {
      final start = Future.delayed(
        const Duration(milliseconds: 300),
        sfx.pencilDrawStart,
      );
      final finish = Future.delayed(const Duration(milliseconds: 1900), () {
        sfx.pencilDrawStop();
        if (copy.isNight) {
          sfx.nightBloom();
        } else {
          sfx.dayBloom();
        }
        showText.value = true;
      });
      return () {
        start.ignore();
        finish.ignore();
        sfx.pencilDrawStop();
      };
    }, [copy]);

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 2),
          Center(
            child: copy.isNight
                ? const HandDrawnMoon(startDelay: Duration(milliseconds: 300))
                : const HandDrawnSun(startDelay: Duration(milliseconds: 300)),
          ),
          const SizedBox(height: 36),
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
                sfx.revealWhoosh();
                showButton.value = true;
              },
            ),
          ],
          const Spacer(flex: 2),
          Center(
            child: AnimatedOpacity(
              opacity: showButton.value ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: showButton.value
                  ? HandDrawnButton(
                      label: 'continue',
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
    // Day-part boundaries live in [TimeGreeting]; the onboarding scene keeps its
    // own longer, lowercase devotional copy but shares the same clock logic.
    final part = TimeGreeting.forHour(hour).part;
    switch (part) {
      case DayPart.morning:
        return const _SceneCopy(
          isNight: false,
          headline: 'good morning.',
          body: 'his mercies are new with the light.\n'
              'before the day fills up, pause here.',
        );
      case DayPart.afternoon:
        return const _SceneCopy(
          isNight: false,
          headline: 'good afternoon.',
          body: 'the day is loud and full.\n'
              'step aside for just a moment.',
        );
      case DayPart.evening:
        return const _SceneCopy(
          isNight: true,
          headline: 'good evening.',
          body: 'as the light grows soft,\n'
              'lay down what was heavy to carry.',
        );
      case DayPart.night:
        return const _SceneCopy(
          isNight: true,
          headline: 'abide with me.',
          body: 'fast falls the eventide.\n'
              'he gives his beloved sleep.',
        );
    }
  }
}
