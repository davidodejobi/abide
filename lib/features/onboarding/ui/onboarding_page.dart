import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';

import 'package:openbaptisthymnal/features/plus/domain/plus_rules.dart';
import 'package:openbaptisthymnal/features/plus/providers/plus_providers.dart';

import '../providers/onboarding_provider.dart';
import 'screens/bible_screen.dart';
import 'screens/name_screen.dart';
import 'screens/plan_screen.dart';
import 'screens/plus_offer_screen.dart';
import 'screens/welcome_screen.dart';

/// Hosts the first-run flow: welcome, then three steps on the road (Bible,
/// plan, name). Steps whose data the app cannot store yet are not shown.
@RoutePage()
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  static const _steps = 3;
  int _page = 0;

  void _goTo(int page) => setState(() => _page = page);

  void _finish() => context.router.replaceAll([const DashboardRoute()]);

  /// Onboarding is saved; offer Plus once, softly, to readers without it.
  void _afterName() => showOnboardingOffer(ref.read(plusProvider))
      ? _goTo(4)
      : _finish();

  Widget _buildPage() {
    switch (_page) {
      case 0:
        return WelcomeScreen(key: const ValueKey(0), onNext: () => _goTo(1));
      case 1:
        return BibleScreen(
          key: const ValueKey(1),
          step: 1,
          total: _steps,
          onNext: () => _goTo(2),
          onBack: () => _goTo(0),
        );
      case 2:
        return PlanScreen(
          key: const ValueKey(2),
          step: 2,
          total: _steps,
          onNext: () => _goTo(3),
          onBack: () => _goTo(1),
        );
      case 3:
        return NameScreen(
          key: const ValueKey(3),
          step: 3,
          total: _steps,
          onDone: _afterName,
          onBack: () => _goTo(2),
        );
      default:
        return PlusOfferScreen(key: const ValueKey(4), onDone: _finish);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(onboardingProvider.select((s) => s.saving));
    return PopScope(
      canPop: _page == 0 && !saving,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || saving || _page == 0) return;
        // Everything is saved by the offer step, so back means skip it.
        _page == 4 ? _finish() : _goTo(_page - 1);
      },
      child: Scaffold(
        backgroundColor: context.lum.bgPage,
        body: AnimatedSwitcher(
          duration: LumMotion.base,
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: _buildPage(),
        ),
      ),
    );
  }
}
