import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/providers/service_providers.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';

import '../domain/plus_rules.dart';
import '../plus_config.dart';
import '../providers/plus_providers.dart';

/// Day-5 trial reminder: charge date, price, and a way to manage or dismiss.
/// Shows nothing outside days 5 to 7 of a live trial. [now] is for tests.
class TrialReminderCard extends ConsumerWidget {
  const TrialReminderCard({super.key, this.now});
  final DateTime? now;

  static String _date(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(plusProvider);
    final at = now ?? DateTime.now();
    if (!trialReminderDue(e, at)) return const SizedBox.shrink();
    final end = trialEnd(e.trialStartedAt!);
    final daysLeft = end.difference(at).inDays.clamp(1, PlusConfig.trialDays);
    final c = context.lum;
    final manageUrl = defaultTargetPlatform == TargetPlatform.android
        ? 'https://play.google.com/store/account/subscriptions'
        : 'https://apps.apple.com/account/subscriptions';
    return Container(
      margin: const EdgeInsets.only(bottom: LumSpace.lg),
      padding: const EdgeInsets.all(LumSpace.lg),
      decoration: BoxDecoration(
        color: c.bgSurface,
        borderRadius: BorderRadius.circular(LumRadius.lg),
        border: Border.all(color: c.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(PlusStrings.reminderTitle(daysLeft),
              style: LumText.bodyEmphasized.copyWith(color: c.textPrimary)),
          const SizedBox(height: LumSpace.xs),
          Text(PlusStrings.reminderBody(_date(end), PlusConfig.annualPrice),
              style: LumText.subheadline.copyWith(color: c.textSecondary)),
          Row(
            children: [
              TextButton(
                onPressed: () =>
                    ref.read(urlLauncherServiceProvider).openUrl(manageUrl),
                child: const Text(PlusStrings.manage),
              ),
              TextButton(
                onPressed: () => ref.read(plusProvider.notifier).dismissReminder(),
                child: const Text('Got it'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
