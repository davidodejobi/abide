import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/core/theme/app_theme.dart';
import 'package:openbaptisthymnal/features/daily/domain/landmark_glb_loader.dart';
import 'package:openbaptisthymnal/features/daily/domain/road_landmarks.dart';
import 'package:openbaptisthymnal/features/daily/providers/landmark_download_provider.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/onboarding_strings.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/screens/road_download_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/pump_app.dart';
import 'dart:typed_data';

class _MemCache implements GlbCache {
  final files = <String, Uint8List>{};
  @override
  Future<Uint8List?> read(String name) async => files[name];
  @override
  Future<void> write(String name, Uint8List bytes) async => files[name] = bytes;
  @override
  Future<bool> has(String name) async => files.containsKey(name);
  @override
  Future<void> delete(String name) async => files.remove(name);
}

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<(ProviderContainer, List<String>)> pump(WidgetTester t) async {
    final nav = <String>[];
    final loader = LandmarkGlbLoader(
      cache: _MemCache(),
      cdnBase: 'https://cdn.test',
      loadBundled: (_) async => throw StateError('none'),
      fetch: (_) async => null, // downloads fail quietly in this test
    );
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      landmarkLoaderProvider.overrideWithValue(loader),
      remoteLandmarkModelsProvider.overrideWith((_) async => [
            for (var i = 0; i < 2; i++)
              LandmarkModelInfo(
                  art: 'm$i',
                  title: 'M$i',
                  sha256: 'a' * 64,
                  bundled: false,
                  bytes: 2400000),
          ]),
    ]);
    addTearDown(c.dispose);
    LandmarkDownloadNotifier.retryDelay = Duration.zero;
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: RoadDownloadScreen(
            step: 3,
            total: 4,
            onNext: () => nav.add('next'),
            onBack: () {},
          ),
        ),
      ),
    ));
    await t.pump(const Duration(milliseconds: 200));
    await t.pump(const Duration(milliseconds: 200));
    return (c, nav);
  }

  testWidgets('shows the copy and the real size', (t) async {
    await pump(t);
    expect(find.text(OnboardingStrings.roadTitle), findsOneWidget);
    expect(find.text(OnboardingStrings.roadBody), findsOneWidget);
    expect(find.text(OnboardingStrings.roadSize('4.8 MB')), findsOneWidget);
    for (final s in [OnboardingStrings.roadBody, OnboardingStrings.roadSizeUnknown]) {
      expect(s.contains('—'), isFalse);
      expect(s.toLowerCase().contains('bible'), isFalse);
    }
    await t.flushTimers();
  });

  testWidgets('Download now saves the choice and moves on at once', (t) async {
    final (c, nav) = await pump(t);
    await t.tap(find.text(OnboardingStrings.downloadNow));
    await t.pump();
    expect(nav, ['next']);
    expect(c.read(landmarkDownloadProvider).accepted, isTrue);
    await t.pump(const Duration(seconds: 1));
    await t.flushTimers();
  });

  testWidgets('Later saves the choice and moves on', (t) async {
    final (c, nav) = await pump(t);
    await t.tap(find.text(OnboardingStrings.later));
    await t.pump();
    expect(nav, ['next']);
    expect(c.read(landmarkDownloadProvider).declined, isTrue);
    expect(prefs.getString('landmark_download_choice'), 'declined');
    await t.flushTimers();
  });
}
