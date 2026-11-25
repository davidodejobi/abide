import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';

import '../data/entitlement_repository.dart';
import '../data/purchase_service.dart';
import '../domain/plus_rules.dart';
import '../plus_config.dart';

final entitlementRepositoryProvider = Provider<EntitlementRepository>(
    (ref) => FakeEntitlementRepository(ref.watch(sharedPreferencesProvider)));

/// Release gate. Tests override this; see [PlusConfig.enabled].
final plusEnabledProvider = Provider<bool>((ref) => PlusConfig.enabled);

final purchaseServiceProvider = Provider<PurchaseService>((ref) =>
    ref.watch(plusEnabledProvider)
        ? const FakePurchaseService()
        : const DisabledPurchaseService());

final plusProvider =
    NotifierProvider<PlusNotifier, Entitlement>(PlusNotifier.new);

class PlusNotifier extends Notifier<Entitlement> {
  @override
  Entitlement build() => ref.watch(plusEnabledProvider)
      ? ref.read(entitlementRepositoryProvider).read()
      : const Entitlement(); // never grants while switched off

  Future<void> _set(Entitlement e) async {
    await ref.read(entitlementRepositoryProvider).write(e);
    state = e;
  }

  Future<PurchaseOutcome> startTrial(PlusPlan plan) async {
    final r = await ref.read(purchaseServiceProvider).startTrial(plan);
    if (r == PurchaseOutcome.success) {
      await _set(Entitlement(
          isPlus: true, trialStartedAt: DateTime.now(), plan: plan));
    }
    return r;
  }

  Future<PurchaseOutcome> restore() async {
    final r = await ref.read(purchaseServiceProvider).restore();
    if (r == PurchaseOutcome.success) await _set(state.copyWith(isPlus: true));
    return r;
  }

  Future<void> dismissReminder() =>
      _set(state.copyWith(reminderDismissed: true));

  /// Debug only: flip Plus without a purchase.
  Future<void> debugSet(bool plus) async {
    if (!ref.read(plusEnabledProvider)) return;
    await _set(plus ? const Entitlement(isPlus: true) : const Entitlement());
  }
}
