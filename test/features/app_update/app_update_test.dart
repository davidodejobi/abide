import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/core/storage/storage_service.dart';
import 'package:openbaptisthymnal/core/theme/app_theme.dart';
import 'package:openbaptisthymnal/features/app_update/data/app_config_repository.dart';
import 'package:openbaptisthymnal/features/app_update/domain/app_config.dart';
import 'package:openbaptisthymnal/features/app_update/providers/app_update_provider.dart';
import 'package:openbaptisthymnal/features/app_update/ui/app_update_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

AppConfig cfg({
  String min = '0.3.0',
  String latest = '0.3.1',
  bool maintenance = false,
}) =>
    AppConfig(minVersion: min, latestVersion: latest, maintenance: maintenance);

Future<ProviderContainer> container(
  AppConfigFetcher fetcher, {
  String installed = '0.2.0',
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(sp),
    installedVersionProvider.overrideWith((_) async => installed),
    appConfigRepositoryProvider.overrideWith(
      (ref) => AppConfigRepository(StorageService(sp), fetcher: fetcher),
    ),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('compareVersions is numeric and ignores build suffix', () {
    expect(compareVersions('0.10.0', '0.9.0'), 1);
    expect(compareVersions('0.3', '0.3.0'), 0);
    expect(compareVersions('0.3.0+9', '0.3.0'), 0);
    expect(compareVersions('0.2.9', '0.3.0'), -1);
  });

  group('decideStatus', () {
    test('forced, optional, maintenance, none', () {
      expect(
          decideStatus(installed: '0.2.0', config: cfg()), UpdateStatus.forced);
      expect(decideStatus(installed: '0.3.0', config: cfg()),
          UpdateStatus.optional);
      expect(
          decideStatus(installed: '0.3.1', config: cfg()), UpdateStatus.none);
      expect(
        decideStatus(installed: '0.3.1', config: cfg(maintenance: true)),
        UpdateStatus.maintenance,
      );
    });
    test('forced beats maintenance; dismissals respected', () {
      expect(
        decideStatus(installed: '0.2.0', config: cfg(maintenance: true)),
        UpdateStatus.forced,
      );
      expect(
        decideStatus(
            installed: '0.3.0', config: cfg(), dismissedLatest: '0.3.1'),
        UpdateStatus.none,
      );
      expect(
        decideStatus(
            installed: '0.3.0', config: cfg(), dismissedLatest: '0.3.0'),
        UpdateStatus.optional,
      );
      expect(
        decideStatus(
          installed: '0.3.1',
          config: cfg(maintenance: true),
          maintenanceDismissed: true,
        ),
        UpdateStatus.none,
      );
    });
    test('no config fails open', () {
      expect(decideStatus(installed: '0.0.1', config: null), UpdateStatus.none);
    });
  });

  group('notifier', () {
    test('network failure with no cache fails open', () async {
      final c = await container(() async => null);
      await c.read(appUpdateProvider.notifier).check();
      expect(c.read(appUpdateProvider).status, UpdateStatus.none);
    });

    test('fetch caches, and the cache gates when offline', () async {
      final c = await container(() async => cfg());
      await c.read(appUpdateProvider.notifier).check();
      expect(c.read(appUpdateProvider).status, UpdateStatus.forced);

      final sp = c.read(sharedPreferencesProvider);
      final offline = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
        installedVersionProvider.overrideWith((_) async => '0.2.0'),
        appConfigRepositoryProvider.overrideWith(
          (ref) => AppConfigRepository(StorageService(sp),
              fetcher: () async => null),
        ),
      ]);
      addTearDown(offline.dispose);
      await offline.read(appUpdateProvider.notifier).check();
      expect(offline.read(appUpdateProvider).status, UpdateStatus.forced);
      expect(offline.read(appUpdateProvider).checkedAt, isNotNull);
    });

    Future<void> seedCache(
      SharedPreferences sp,
      AppConfig config,
      DateTime at,
    ) =>
        StorageService(sp).saveAppConfigCache(
          jsonEncode({
            'config': config.toJson(),
            'checkedAt': at.toIso8601String(),
          }),
        );

    test('cached maintenance is ignored, fresh maintenance is honoured',
        () async {
      final c = await container(() async => null, installed: '0.3.1');
      await seedCache(c.read(sharedPreferencesProvider), cfg(maintenance: true),
          DateTime.now());
      await c.read(appUpdateProvider.notifier).check();
      expect(c.read(appUpdateProvider).status, UpdateStatus.none);

      final f = await container(() async => cfg(maintenance: true),
          installed: '0.3.1');
      await f.read(appUpdateProvider.notifier).check();
      expect(f.read(appUpdateProvider).status, UpdateStatus.maintenance);
    });

    test('cached forced gate expires after 7 days', () async {
      final c = await container(() async => null);
      final sp = c.read(sharedPreferencesProvider);
      await seedCache(
          sp, cfg(), DateTime.now().subtract(const Duration(days: 6)));
      await c.read(appUpdateProvider.notifier).check();
      expect(c.read(appUpdateProvider).status, UpdateStatus.forced);

      final old = await container(() async => null);
      await seedCache(old.read(sharedPreferencesProvider), cfg(),
          DateTime.now().subtract(const Duration(days: 8)));
      await old.read(appUpdateProvider.notifier).check();
      expect(old.read(appUpdateProvider).status, UpdateStatus.none);
    });

    test('concurrent check() calls fetch once', () async {
      var fetches = 0;
      final c = await container(() async {
        fetches++;
        return cfg();
      });
      final n = c.read(appUpdateProvider.notifier);
      await Future.wait([n.check(), n.check()]);
      expect(fetches, 1);
    });

    test('optional is dismissed once per latestVersion', () async {
      final c =
          await container(() async => cfg(min: '0.1.0'), installed: '0.3.0');
      final n = c.read(appUpdateProvider.notifier);
      await n.check();
      expect(c.read(appUpdateProvider).status, UpdateStatus.optional);
      n.dismissOptional();
      expect(c.read(appUpdateProvider).status, UpdateStatus.none);
      await n.check();
      expect(c.read(appUpdateProvider).status, UpdateStatus.none);
    });
  });

  test('storeUrlFor falls back when the config has no url', () {
    expect(storeUrlFor(null, ios: false),
        'https://play.google.com/store/apps/details?id=com.openbaptisthymnal');
    expect(storeUrlFor(cfg(), ios: true), 'https://apps.apple.com/');
    const withUrl = AppConfig(
        minVersion: '1',
        latestVersion: '1',
        androidStoreUrl: 'https://x.test/a');
    expect(storeUrlFor(withUrl, ios: false), 'https://x.test/a');
  });

  testWidgets('forced gate hides the app from semantics and offers Check again',
      (tester) async {
    final handle = tester.ensureSemantics();
    final c = await container(() async => cfg());
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const AppUpdateOverlay(
          child: Scaffold(body: Center(child: Text('Underneath'))),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.semantics.byLabel('Underneath'), findsNothing);
    expect(find.semantics.byLabel('Check again'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('android back dismisses the optional sheet, not the gate',
      (tester) async {
    Future<void> pump(ProviderContainer c) async {
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AppUpdateOverlay(child: Scaffold(body: Text('App'))),
        ),
      ));
      await tester.pumpAndSettle();
    }

    final opt =
        await container(() async => cfg(min: '0.1.0'), installed: '0.3.0');
    await pump(opt);
    expect(opt.read(appUpdateProvider).status, UpdateStatus.optional);
    await WidgetsBinding.instance.handlePopRoute();
    await tester.pumpAndSettle();
    expect(opt.read(appUpdateProvider).status, UpdateStatus.none);

    await tester.pumpWidget(const SizedBox());
    final forced = await container(() async => cfg());
    await pump(forced);
    await WidgetsBinding.instance.handlePopRoute();
    await tester.pumpAndSettle();
    expect(forced.read(appUpdateProvider).status, UpdateStatus.forced);
  });

  testWidgets('forced gate shows and blocks the app underneath',
      (tester) async {
    var taps = 0;
    final c = await container(() async => cfg());
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: AppUpdateOverlay(
          child: Scaffold(
            body: Center(
              child: TextButton(
                  onPressed: () => taps++, child: const Text('Underneath')),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Update Lumway to keep reading'), findsOneWidget);
    expect(find.text('Later'), findsNothing);
    await tester.tap(find.text('Underneath'), warnIfMissed: false);
    expect(taps, 0);
  });
}
