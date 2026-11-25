import 'package:shared_preferences/shared_preferences.dart';

import '../domain/plus_rules.dart';
import 'purchase_service.dart';

abstract interface class EntitlementRepository {
  Entitlement read();
  Future<void> write(Entitlement entitlement);
}

/// Stand-in until a billing provider is chosen. Free by default, kept in
/// SharedPreferences so the debug toggle survives restarts.
class FakeEntitlementRepository implements EntitlementRepository {
  FakeEntitlementRepository(this._prefs);
  final SharedPreferences _prefs;

  static const _plus = 'plus_active';
  static const _trial = 'plus_trial_start';
  static const _dismissed = 'plus_reminder_dismissed';
  static const _plan = 'plus_plan';

  @override
  Entitlement read() {
    final ms = _prefs.getInt(_trial);
    return Entitlement(
      isPlus: _prefs.getBool(_plus) ?? false,
      trialStartedAt: ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms),
      reminderDismissed: _prefs.getBool(_dismissed) ?? false,
      plan: PlusPlan.values.asNameMap()[_prefs.getString(_plan)],
    );
  }

  @override
  Future<void> write(Entitlement e) async {
    await _prefs.setBool(_plus, e.isPlus);
    await _prefs.setBool(_dismissed, e.reminderDismissed);
    final plan = e.plan;
    if (plan == null) {
      await _prefs.remove(_plan);
    } else {
      await _prefs.setString(_plan, plan.name);
    }
    final start = e.trialStartedAt;
    if (start == null) {
      await _prefs.remove(_trial);
    } else {
      await _prefs.setInt(_trial, start.millisecondsSinceEpoch);
    }
  }
}
