import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/features/daily/providers/landmark_download_provider.dart';

import '../providers/onboarding_provider.dart';
import 'screens/bible_screen.dart';
import 'screens/name_screen.dart';
import 'screens/plan_screen.dart';
import 'screens/road_download_screen.dart';
import 'screens/welcome_screen.dart';

/// Hosts the first-run flow: welcome, then up to four steps on the road (Bible,
/// plan, road download, name). The download step is left out where nothing can
/// be kept on disk (web).
@RoutePage()
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int _page = 0;

  // Pages: 0 welcome, 1 bible, 2 plan, 3 road (only when supported), then name.
  late final bool _road =
      ref.read(landmarkDownloadProvider.notifier).supported;
  int get _steps => _road ? 4 : 3;
  int get _namePage => _road ? 4 : 3;

  void _goTo(int page) => setState(() => _page = page);

  void _finish() => context.router.replaceAll([const DashboardRoute()]);

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
      default:
        if (_road && _page == 3) {
          return RoadDownloadScreen(
            key: const ValueKey(3),
            step: 3,
            total: _steps,
            onNext: () => _goTo(4),
            onBack: () => _goTo(2),
          );
        }
        return NameScreen(
          key: ValueKey(_namePage),
          step: _namePage,
          total: _steps,
          onDone: _finish,
          onBack: () => _goTo(_namePage - 1),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(onboardingProvider.select((s) => s.saving));
    return PopScope(
      canPop: _page == 0 && !saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !saving && _page > 0) _goTo(_page - 1);
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
