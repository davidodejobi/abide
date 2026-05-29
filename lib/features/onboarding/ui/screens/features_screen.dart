import 'dart:async';

import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/widgets/hand_drawn_button.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/widgets/typewriter_text.dart';

/// Third onboarding screen — describes what Abide is growing into: a place to
/// sing, study, take sermon notes, and walk together as a community.
class FeaturesScreen extends StatefulWidget {
  const FeaturesScreen({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  State<FeaturesScreen> createState() => _FeaturesScreenState();
}

class _FeaturesScreenState extends State<FeaturesScreen> {
  final _scrollController = ScrollController();
  Timer? _autoScroll;
  bool _showBody = false;
  bool _showMore = false;
  bool _showButton = false;

  @override
  void initState() {
    super.initState();
    // Keep the latest line in view as the typewriter grows the text.
    _autoScroll = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (_scrollController.offset < max) {
        _scrollController.animateTo(
          max,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScroll?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 64),
                  TypewriterText(
                    text: 'a home for your faith.',
                    style: AppTextStyles.doodleHeadline(color: ink),
                    startDelay: const Duration(milliseconds: 300),
                    onComplete: () => setState(() => _showBody = true),
                  ),
                  const SizedBox(height: 24),
                  if (_showBody)
                    TypewriterText(
                      text: 'sing the hymns you love,\n'
                          'with the words right in front of you.\n'
                          'study the Bible at your own pace.\n'
                          'take notes as the sermon unfolds,\n'
                          'and keep them in one quiet place.',
                      style: AppTextStyles.doodleBody(color: ink),
                      perCharacter: const Duration(milliseconds: 28),
                      onComplete: () => setState(() => _showMore = true),
                    ),
                  const SizedBox(height: 20),
                  if (_showMore)
                    TypewriterText(
                      text: 'soon, share those notes with friends,\n'
                          'study devotionals together,\n'
                          'keep one another accountable,\n'
                          'and grow — not on your own,\n'
                          'but as a small, faithful community.',
                      style: AppTextStyles.doodleBody(color: ink),
                      perCharacter: const Duration(milliseconds: 28),
                      onComplete: () => setState(() => _showButton = true),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: AnimatedOpacity(
              opacity: _showButton ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !_showButton,
                child: HandDrawnButton(
                  label: 'continue',
                  onTap: widget.onNext,
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
