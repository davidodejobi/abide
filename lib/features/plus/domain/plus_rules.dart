import '../data/purchase_service.dart';
import '../plus_config.dart';

/// What the app knows about the reader's Plus access.
class Entitlement {
  const Entitlement({
    this.isPlus = false,
    this.trialStartedAt,
    this.reminderDismissed = false,
    this.plan,
  });

  final bool isPlus;
  final PlusPlan? plan;
  final DateTime? trialStartedAt;
  final bool reminderDismissed;

  Entitlement copyWith({bool? isPlus, bool? reminderDismissed}) => Entitlement(
        isPlus: isPlus ?? this.isPlus,
        trialStartedAt: trialStartedAt,
        plan: plan,
        reminderDismissed: reminderDismissed ?? this.reminderDismissed,
      );
}

/// 1-based day of the trial. Day 1 is the day it started.
int trialDay(DateTime start, DateTime now) => now.difference(start).inDays + 1;

DateTime trialEnd(DateTime start) =>
    start.add(const Duration(days: PlusConfig.trialDays));

/// The day-5 reminder: on days 5 to 7 of a live trial, until dismissed. It
/// states the charge date and price, and links to manage the subscription.
bool trialReminderDue(Entitlement e, DateTime now) {
  final start = e.trialStartedAt;
  if (!e.isPlus || start == null || e.reminderDismissed) return false;
  final day = trialDay(start, now);
  return day >= PlusConfig.reminderDay && day <= PlusConfig.trialDays;
}

/// Release gate selector, see [PlusConfig.enabled].
bool plusFeaturesEnabled({required bool debug, required bool flag}) =>
    debug || flag;

/// The soft offer at the end of onboarding: only when Plus is switched on and
/// the reader does not have it.
bool showOnboardingOffer(Entitlement e, {required bool enabled}) =>
    enabled && !e.isPlus;

/// Only [PlusFeature] extras are gated, and only when Plus is switched on.
/// Reading is never asked about.
bool isGated(Entitlement e, PlusFeature feature, {required bool enabled}) =>
    enabled && !e.isPlus;
