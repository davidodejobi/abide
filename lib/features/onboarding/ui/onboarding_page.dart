import 'package:audioplayers/audioplayers.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/screens/features_screen.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/screens/name_screen.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/screens/scene_screen.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/screens/welcome_screen.dart';

/// Hosts the hand-drawn onboarding flow and owns the background audio.
@RoutePage()
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _audioAsset = 'audio/abide_intro.mp3';

  final AudioPlayer _player = AudioPlayer();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _startAudio();
  }

  Future<void> _startAudio() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(0.6);
      await _player.play(AssetSource(_audioAsset));
    } catch (_) {
      // No audio asset yet — flow continues silently.
    }
  }

  Future<void> _fadeOutAudio() async {
    try {
      for (var v = 0.6; v >= 0; v -= 0.1) {
        await _player.setVolume(v.clamp(0, 1));
        await Future.delayed(const Duration(milliseconds: 60));
      }
      await _player.stop();
    } catch (_) {}
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _goTo(int page) => setState(() => _page = page);

  Future<void> _finish() async {
    await _fadeOutAudio();
    if (!mounted) return;
    context.router.replaceAll([const DashboardRoute()]);
  }

  Widget _buildPage() {
    switch (_page) {
      case 0:
        return WelcomeScreen(key: const ValueKey(0), onNext: () => _goTo(1));
      case 1:
        return SceneScreen(key: const ValueKey(1), onNext: () => _goTo(2));
      case 2:
        return FeaturesScreen(key: const ValueKey(2), onNext: () => _goTo(3));
      default:
        return NameScreen(key: const ValueKey(3), onDone: _finish);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: _buildPage(),
        ),
      ),
    );
  }
}
