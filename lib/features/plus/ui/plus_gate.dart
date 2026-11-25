import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/widgets/lum_button.dart';

import '../data/purchase_service.dart';
import '../domain/plus_rules.dart';
import '../plus_config.dart';
import '../providers/plus_providers.dart';

/// Call where a Plus feature is touched. Returns true when the reader has Plus
/// (already, or after the sheet), false when they chose "Not now". Never call
/// it for Scripture, hymns or the year plan.
Future<bool> requirePlus(
    BuildContext context, WidgetRef ref, PlusFeature feature) async {
  if (!isGated(ref.read(plusProvider), feature)) return true;
  final got = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => PlusGateSheet(feature: feature),
  );
  return got ?? false;
}

/// One feature, the price, the trial, and an equal-weight "Not now".
class PlusGateSheet extends HookConsumerWidget {
  const PlusGateSheet({super.key, required this.feature});
  final PlusFeature feature;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lum;
    final busy = useState(false);
    final failed = useState(false);

    Future<void> start() async {
      if (busy.value) return;
      busy.value = true;
      failed.value = false;
      final r = await ref.read(plusProvider.notifier).startTrial(PlusPlan.annual);
      if (!context.mounted) return;
      busy.value = false;
      if (r == PurchaseOutcome.success) {
        Navigator.of(context).pop(true);
      } else {
        failed.value = true;
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            LumSize.screenGutter, 0, LumSize.screenGutter, LumSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(feature.title,
                  style: LumText.title2.copyWith(color: c.textPrimary)),
            ),
            const SizedBox(height: LumSpace.sm),
            Text(PlusStrings.gateBody(feature),
                style: LumText.body.copyWith(color: c.textSecondary)),
            const SizedBox(height: LumSpace.sm),
            Text(PlusStrings.thenPrice(PlusConfig.annualPrice, 'year'),
                style: LumText.footnote.copyWith(color: c.textSecondary)),
            if (failed.value) ...[
              const SizedBox(height: LumSpace.sm),
              Semantics(
                liveRegion: true,
                child: Text(PlusStrings.failed,
                    style: LumText.footnote.copyWith(color: c.textDanger)),
              ),
            ],
            const SizedBox(height: LumSpace.lg),
            LumButton(
              label: PlusStrings.startTrial,
              kind: LumButtonKind.gold,
              onPressed: busy.value ? null : start,
            ),
            const SizedBox(height: LumSpace.md),
            LumButton(
              label: PlusStrings.notNow,
              kind: LumButtonKind.secondary,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                  context.router.push(const PlusRoute());
                },
                child: Text(PlusStrings.seeAll,
                    style: LumText.subheadline.copyWith(color: c.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
