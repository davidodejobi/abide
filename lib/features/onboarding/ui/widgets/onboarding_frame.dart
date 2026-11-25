import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/widgets/lum_button.dart';
import 'package:openbaptisthymnal/core/widgets/lum_circle_button.dart';
import 'package:openbaptisthymnal/features/daily/ui/widgets/road_scene.dart';

import '../onboarding_strings.dart';
import 'step_road.dart';

/// The shared onboarding layout (Figma K3): the road valley on top with the
/// traveller just before stop 1, a rounded panel below holding the step, and
/// the primary button pinned at the panel's foot.
///
/// [step] is 1-based; null is the welcome screen, which shows a taller scene
/// and no back button or progress.
class OnboardingFrame extends StatelessWidget {
  const OnboardingFrame({
    super.key,
    required this.child,
    required this.primaryLabel,
    required this.onPrimary,
    this.step,
    this.totalSteps = 0,
    this.onBack,
  });

  final int? step;
  final int totalSteps;
  final VoidCallback? onBack;
  final Widget child;
  final String primaryLabel;
  final VoidCallback? onPrimary;

  static const double _maxWidth = 430;
  // Where stop 1 sits on the 390 x 560 scene (slot 3 centre).
  static const double _coinY = 287;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    final welcome = step == null;
    // Scaffold consumes viewInsets for its body, so read the real keyboard
    // height from the view instead.
    final view = View.of(context);
    final keyboard = view.viewInsets.bottom > 0;
    return LayoutBuilder(builder: (context, box) {
      final width = box.maxWidth < _maxWidth ? box.maxWidth : _maxWidth;
      final k = width / RoadScene.designWidth;
      final top = MediaQuery.paddingOf(context).top;
      // The scene takes a share of the height; with the keyboard up it shrinks
      // to just the top bar so the field and button stay in view.
      final sceneH = keyboard
          ? top + 72
          : (box.maxHeight * (welcome ? 0.56 : 0.3)).clamp(top + 150, 520.0);
      final offset = welcome || keyboard
          ? 0.0
          : (_coinY * k - sceneH * 0.5).clamp(0.0, double.infinity);

      return Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: c.bgPage)),
          Positioned(
            top: -offset,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.topCenter,
              child: RoadScene(
                width: width,
                mood: RoadMood.day,
                currentDay: 1,
                totalDays: 90,
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(height: sceneH - 28),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _maxWidth),
                    child: _Panel(
                      primaryLabel: primaryLabel,
                      onPrimary: onPrimary,
                      child: child,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!welcome)
            Positioned(
              top: top + LumSpace.sm,
              left: LumSize.screenGutter,
              right: LumSize.screenGutter,
              child: Align(
                alignment: Alignment.topLeft,
                child: Row(
                  children: [
                    LumCircleButton(
                      icon: Icons.arrow_back_rounded,
                      label: OnboardingStrings.back,
                      onPressed: onBack,
                    ),
                    const SizedBox(width: LumSpace.md),
                    Flexible(child: StepRoad(current: step!, total: totalSteps)),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    required this.primaryLabel,
    required this.onPrimary,
  });

  final Widget child;
  final String primaryLabel;
  final VoidCallback? onPrimary;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.scenePanel,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: c.sceneShadow,
            blurRadius: 28,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  LumSpace.xl, LumSpace.xl, LumSpace.xl, LumSpace.lg),
              child: SizedBox(width: double.infinity, child: child),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                LumSpace.xl, 0, LumSpace.xl, bottom + LumSpace.lg),
            child: SizedBox(
              width: double.infinity,
              child: LumButton(label: primaryLabel, onPressed: onPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
