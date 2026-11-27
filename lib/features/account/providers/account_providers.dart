import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/config/supabase_config.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/fake_auth_repository.dart';
import '../data/supabase_auth_repository.dart';
import '../domain/auth_repository.dart';

/// Supabase whenever it is configured; otherwise the fake in debug (or with
/// `--dart-define=FAKE_AUTH=true`); otherwise null, which hides the account UI.
final authRepositoryProvider = Provider<AuthRepository?>((ref) {
  if (supabaseConfigured) {
    return SupabaseAuthRepository.native(Supabase.instance.client.auth);
  }
  return kDebugMode || const bool.fromEnvironment('FAKE_AUTH')
      ? FakeAuthRepository()
      : null;
});

final accountProvider = StreamProvider<AuthAccount>((ref) =>
    ref.watch(authRepositoryProvider)?.watchAccount() ?? const Stream.empty());

const _promptedKey = 'save_road_prompted';

/// Whether the "Save your road" sheet has already been offered automatically.
/// Set the moment it is shown, so it never nags a second time. The You tab
/// entry ignores this.
final saveRoadPromptedProvider =
    NotifierProvider<SaveRoadPromptedNotifier, bool>(
        SaveRoadPromptedNotifier.new);

class SaveRoadPromptedNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(sharedPreferencesProvider).getBool(_promptedKey) ?? false;

  void markShown() {
    state = true;
    ref.read(sharedPreferencesProvider).setBool(_promptedKey, true);
  }
}
