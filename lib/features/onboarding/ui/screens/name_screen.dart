import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/features/onboarding/providers/onboarding_provider.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/widgets/hand_drawn_button.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/widgets/hand_drawn_field.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/widgets/typewriter_text.dart';

/// Final onboarding screen — asks for the user's name, saves it, finishes.
class NameScreen extends ConsumerStatefulWidget {
  const NameScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends ConsumerState<NameScreen> {
  final _controller = TextEditingController();
  bool _showInput = false;
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    ref.read(onboardingProvider.notifier).setName(_controller.text);
    await ref.read(onboardingProvider.notifier).complete();
    widget.onDone();
  }

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
            text: 'one last thing —\nwhat should we call you?',
            style: AppTextStyles.doodleHeadline(color: ink),
            startDelay: const Duration(milliseconds: 300),
            onComplete: () => setState(() => _showInput = true),
          ),
          const SizedBox(height: 12),
          Text(
            'so this place can feel like yours.',
            style: AppTextStyles.doodleBody(color: ink.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 32),
          if (_showInput)
            AnimatedOpacity(
              opacity: _showInput ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: HandDrawnField(
                controller: _controller,
                hintText: 'your name',
                onSubmitted: (_) => _finish(),
              ),
            ),
          const Spacer(flex: 4),
          Center(
            child: AnimatedOpacity(
              opacity: _showInput ? 1 : 0,
              duration: const Duration(milliseconds: 400),
              child: _showInput
                  ? HandDrawnButton(
                      label: "let's go",
                      onTap: _finish,
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
