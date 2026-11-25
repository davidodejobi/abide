import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';

import '../data/fake_auth_repository.dart';
import '../domain/auth_repository.dart';

/// The one swap point: override with the Supabase repository when it exists.
final authRepositoryProvider =
    Provider<AuthRepository>((ref) => FakeAuthRepository());

final accountProvider = StreamProvider<AuthAccount>(
    (ref) => ref.watch(authRepositoryProvider).watchAccount());

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
