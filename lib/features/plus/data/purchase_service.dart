enum PlusPlan { monthly, annual }

enum SponsorGift { year, month }

enum PurchaseOutcome { success, nothingToRestore, failed }

abstract interface class PurchaseService {
  Future<PurchaseOutcome> startTrial(PlusPlan plan);
  Future<PurchaseOutcome> restore();
  Future<PurchaseOutcome> sponsor(SponsorGift gift);
}

/// Succeeds after a short delay. No money moves. Swap for the real provider.
class FakePurchaseService implements PurchaseService {
  const FakePurchaseService({this.delay = const Duration(milliseconds: 800)});
  final Duration delay;

  Future<PurchaseOutcome> _ok() async {
    await Future<void>.delayed(delay);
    return PurchaseOutcome.success;
  }

  @override
  Future<PurchaseOutcome> startTrial(PlusPlan plan) => _ok();

  @override
  Future<PurchaseOutcome> sponsor(SponsorGift gift) => _ok();

  // Nothing is bought for real, so there is nothing to restore.
  @override
  Future<PurchaseOutcome> restore() async {
    await Future<void>.delayed(delay);
    return PurchaseOutcome.nothingToRestore;
  }
}

/// Used when Plus is switched off (release): nothing can be bought or granted.
class DisabledPurchaseService implements PurchaseService {
  const DisabledPurchaseService();

  @override
  Future<PurchaseOutcome> startTrial(PlusPlan plan) async =>
      PurchaseOutcome.failed;

  @override
  Future<PurchaseOutcome> restore() async => PurchaseOutcome.failed;

  @override
  Future<PurchaseOutcome> sponsor(SponsorGift gift) async =>
      PurchaseOutcome.failed;
}
