import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/widgets/hand_drawn_button.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/widgets/hand_drawn_moon.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/widgets/hand_drawn_sun.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/widgets/typewriter_text.dart';

/// Second onboarding screen — a sun (day) or moon (evening/night) draws itself
/// based on the current time, then a greeting + devotional line type out.
class SceneScreen extends StatefulWidget {
  const SceneScreen({super.key, required this.onNext, this.now});

  final VoidCallback onNext;

  /// Injectable clock for testing; defaults to [DateTime.now] at build time.
  final DateTime? now;

  @override
  State<SceneScreen> createState() => _SceneScreenState();
}

class _SceneScreenState extends State<SceneScreen> {
  late final _SceneCopy _copy;
  bool _showText = false;
  bool _showButton = false;

  @override
  void initState() {
    super.initState();
    _copy = _SceneCopy.forHour((widget.now ?? DateTime.now()).hour);
    // Reveal the text shortly after the celestial body finishes drawing.
    Future.delayed(const Duration(milliseconds: 1900), () {
      if (mounted) setState(() => _showText = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 2),
          Center(
            child: _copy.isNight
                ? const HandDrawnMoon(startDelay: Duration(milliseconds: 300))
                : const HandDrawnSun(startDelay: Duration(milliseconds: 300)),
          ),
          const SizedBox(height: 36),
          if (_showText) ...[
            TypewriterText(
              text: _copy.headline,
              style: AppTextStyles.doodleHeadline(color: ink),
            ),
            const SizedBox(height: 16),
            TypewriterText(
              text: _copy.body,
              style: AppTextStyles.doodleBody(color: ink),
              perCharacter: const Duration(milliseconds: 30),
              startDelay: const Duration(milliseconds: 900),
              onComplete: () => setState(() => _showButton = true),
            ),
          ],
          const Spacer(flex: 2),
          Center(
            child: AnimatedOpacity(
              opacity: _showButton ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: _showButton
                  ? HandDrawnButton(
                      label: 'continue',
                      onTap: widget.onNext,
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
    if (hour >= 5 && hour < 12) {
      return const _SceneCopy(
        isNight: false,
        headline: 'good morning.',
        body: 'his mercies are new with the light.\n'
            'before the day fills up, pause here.\n'
            'open a hymn, read a little of his word,\n'
            'and let your first thoughts be grateful ones.',
      );
    }
    if (hour >= 12 && hour < 17) {
      return const _SceneCopy(
        isNight: false,
        headline: 'good afternoon.',
        body: 'the day is loud and full.\n'
            'step aside for just a moment —\n'
            'breathe, read a verse, and let\n'
            'the noise grow quiet within you.',
      );
    }
    if (hour >= 17 && hour < 21) {
      return const _SceneCopy(
        isNight: true,
        headline: 'good evening.',
        body: 'as the light grows soft,\n'
            'look back and give thanks for the day.\n'
            'lay down what was heavy to carry,\n'
            'and let your heart be still.',
      );
    }
    return const _SceneCopy(
      isNight: true,
      headline: 'abide with me.',
      body: 'fast falls the eventide.\n'
          'the day is done, and you are kept.\n'
          'he gives his beloved sleep —\n'
          'rest now, and abide through the night.',
    );
  }
}
