import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/features/app_update/data/app_config_repository.dart';
import 'package:openbaptisthymnal/features/app_update/domain/app_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

final appConfigRepositoryProvider = Provider<AppConfigRepository>(
  (ref) => AppConfigRepository(ref.watch(storageServiceProvider)),
);

final installedVersionProvider = FutureProvider<String>(
  (ref) async => (await PackageInfo.fromPlatform()).version,
);

class AppUpdateState {
  const AppUpdateState({
    this.status = UpdateStatus.none,
    this.config,
    this.checkedAt,
  });

  final UpdateStatus status;
  final AppConfig? config;
  final DateTime? checkedAt;
}

final appUpdateProvider =
    NotifierProvider<AppUpdateNotifier, AppUpdateState>(AppUpdateNotifier.new);

class AppUpdateNotifier extends Notifier<AppUpdateState> {
  String? _installed;
  AppConfig? _config;
  DateTime? _checkedAt;
  bool _maintenanceDismissed = false;

  @override
  AppUpdateState build() => const AppUpdateState();

  /// Cache first (so a forced gate shows offline), then the network. Never
  /// throws and never blocks the UI: call without awaiting.
  Future<void> check() async {
    try {
      _installed ??= await ref.read(installedVersionProvider.future);
      final repo = ref.read(appConfigRepositoryProvider);
      final cached = repo.cached();
      if (cached != null) _set(cached.config, cached.checkedAt);
      final fresh = await repo.refresh();
      if (fresh != null) _set(fresh.config, fresh.checkedAt);
    } catch (_) {
      // Fail open.
    }
  }

  void dismissOptional() {
    final latest = _config?.latestVersion;
    if (latest != null) {
      ref.read(storageServiceProvider).saveDismissedUpdateVersion(latest);
    }
    _recompute();
  }

  /// Per session: maintenance comes back next launch if still on.
  void dismissMaintenance() {
    _maintenanceDismissed = true;
    _recompute();
  }

  void _set(AppConfig config, DateTime at) {
    _config = config;
    _checkedAt = at;
    _recompute();
  }

  void _recompute() {
    final installed = _installed;
    if (installed == null) return;
    state = AppUpdateState(
      status: decideStatus(
        installed: installed,
        config: _config,
        dismissedLatest:
            ref.read(storageServiceProvider).getDismissedUpdateVersion(),
        maintenanceDismissed: _maintenanceDismissed,
      ),
      config: _config,
      checkedAt: _checkedAt,
    );
  }
}
