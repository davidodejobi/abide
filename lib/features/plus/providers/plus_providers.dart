import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';

import '../data/entitlement_repository.dart';
import '../data/purchase_service.dart';
import '../domain/plus_rules.dart';

final entitlementRepositoryProvider = Provider<EntitlementRepository>(
    (ref) => FakeEntitlementRepository(ref.watch(sharedPreferencesProvider)));

final purchaseServiceProvider =
    Provider<PurchaseService>((ref) => const FakePurchaseService());

final plusProvider =
    NotifierProvider<PlusNotifier, Entitlement>(PlusNotifier.new);

class PlusNotifier extends Notifier<Entitlement> {
  @override
  Entitlement build() => ref.read(entitlementRepositoryProvider).read();

  Future<void> _set(Entitlement e) async {
    await ref.read(entitlementRepositoryProvider).write(e);
    state = e;
  }

  Future<PurchaseOutcome> startTrial(PlusPlan plan) async {
    final r = await ref.read(purchaseServiceProvider).startTrial(plan);
    if (r == PurchaseOutcome.success) {
      await _set(Entitlement(isPlus: true, trialStartedAt: DateTime.now()));
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
  Future<void> debugSet(bool plus) =>
      _set(plus ? const Entitlement(isPlus: true) : const Entitlement());
}
