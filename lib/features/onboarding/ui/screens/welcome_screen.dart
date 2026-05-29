import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/widgets/hand_drawn_button.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/widgets/typewriter_text.dart';

/// First onboarding screen — types a short welcome, then a hand-drawn button.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _showLine2 = false;
  bool _showButton = false;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 3),
          TypewriterText(
            text: 'welcome to abide.',
            style: AppTextStyles.doodleHeadline(color: ink),
            startDelay: const Duration(milliseconds: 350),
            onComplete: () => setState(() => _showLine2 = true),
          ),
          const SizedBox(height: 18),
          if (_showLine2)
            TypewriterText(
              text: 'a quiet corner for your faith —\n'
                  'a place to sing, to study,\n'
                  'to write, and to abide.\n'
                  'not alone, but together.',
              style: AppTextStyles.doodleBody(color: ink),
              perCharacter: const Duration(milliseconds: 30),
              startDelay: const Duration(milliseconds: 250),
              onComplete: () => setState(() => _showButton = true),
            ),
          const Spacer(flex: 4),
          Center(
            child: AnimatedOpacity(
              opacity: _showButton ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: _showButton
                  ? HandDrawnButton(
                      label: 'begin',
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
