import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../../features/account/providers/account_providers.dart';
import '../storage/database/database_provider.dart';
import 'supabase_sync_remote.dart';
import 'sync_remote.dart';
import 'sync_service.dart';

/// Null unless Supabase is configured and initialised, which keeps sync fully
/// off by default.
final syncRemoteProvider = Provider<SyncRemote?>((ref) {
  if (!supabaseConfigured) return null;
  return SupabaseSyncRemote(
    Supabase.instance.client,
    ensureSession: ref.watch(authRepositoryProvider)?.ensureAnonymousSession,
  );
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

    // Resume pulls; pause/hide flush what was written before backgrounding.
    _lifecycle = AppLifecycleListener(
      onResume: () => service.sync(),
      onHide: () => service.sync(),
      onPause: () => service.sync(),
    );
    // Local writes to any synced table (the outbox itself is filled by
    // triggers, which drift cannot see) start a debounced sync.
    final db = ref.watch(appDatabaseProvider);
    _outbox = db
        .tableUpdates(TableUpdateQuery.onAllTables([
      db.notes,
      db.bibleAnnotations,
      db.readingDays,
      db.planSubscriptions,
      db.planDayProgress,
    ]))
        .listen((_) {
      _timer?.cancel();
      _timer = Timer(debounce, service.sync);
    });
    // A new account (sign-in, sign-out) re-keys sync: run it right away.
    ref.listen(accountProvider, (prev, next) {
      if (prev?.value != null && prev!.value != next.value) service.sync();
    });
    unawaited(service.sync());
  }
}

/// Call once at startup. No-op (and no network) without both dart-defines.
Future<void> initSupabaseIfConfigured() async {
  if (!supabaseConfigured) return;
  // Initialise only: restoring a saved session is local. Signing in (a network
  // call) happens lazily on the first sync, never before the first frame.
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
}
