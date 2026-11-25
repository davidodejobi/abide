import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../storage/database/database_provider.dart';
import 'supabase_sync_remote.dart';
import 'sync_remote.dart';
import 'sync_service.dart';

/// Null unless Supabase is configured and initialised, which keeps sync fully
/// off by default.
final syncRemoteProvider = Provider<SyncRemote?>((ref) {
  if (!supabaseConfigured) return null;
  return SupabaseSyncRemote(Supabase.instance.client);
});

final syncServiceProvider = Provider<SyncService?>((ref) {
  final remote = ref.watch(syncRemoteProvider);
  if (remote == null) return null;
  // TODO: also gate on consent / under-13 once the age band exists.
  return SyncService(db: ref.watch(appDatabaseProvider), remote: remote);
});

/// Runs sync on start, on resume, and shortly after local writes.
final syncControllerProvider = NotifierProvider<SyncController, void>(
  SyncController.new,
);

class SyncController extends Notifier<void> {
  static const debounce = Duration(seconds: 3);

  Timer? _timer;
  StreamSubscription<void>? _outbox;
  AppLifecycleListener? _lifecycle;

  @override
  void build() {
    final service = ref.watch(syncServiceProvider);
    ref.onDispose(() {
      _timer?.cancel();
      _outbox?.cancel();
      _lifecycle?.dispose();
    });
    if (service == null) return;

    _lifecycle = AppLifecycleListener(
      onResume: () => service.sync(),
    );
    // Any write to the outbox (made by triggers) means unsynced local changes.
    final db = ref.watch(appDatabaseProvider);
    _outbox = db.select(db.syncOutbox).watch().listen((rows) {
      if (rows.isEmpty) return;
      _timer?.cancel();
      _timer = Timer(debounce, service.sync);
    });
    unawaited(service.sync());
  }
}

/// Call once at startup. No-op (and no network) without both dart-defines.
Future<void> initSupabaseIfConfigured() async {
  if (!supabaseConfigured) return;
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
  final auth = Supabase.instance.client.auth;
  if (auth.currentSession == null) {
    try {
      await auth.signInAnonymously();
    } catch (_) {
      // Offline at first open: reading stays local, sync retries later.
    }
  }
}
