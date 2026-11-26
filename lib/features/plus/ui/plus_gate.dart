import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/widgets/lum_button.dart';

import '../domain/plus_rules.dart';
import '../plus_config.dart';
import '../providers/plus_providers.dart';

/// Call where a Plus feature is touched. Returns true when the feature may be
/// used now: Plus is switched off (release) or the reader has Plus. Returns
/// false after the sheet ("Not now" or "See Plus plans"). Never call it for
/// Scripture, hymns or the year plan.
Future<bool> requirePlus(
  BuildContext context,
  WidgetRef ref,
  PlusFeature feature, {
  void Function()? openPlans,
}) async {
  if (!ref.read(plusEnabledProvider)) return true;
  if (!isGated(ref.read(plusProvider), feature, enabled: true)) return true;
  final plans = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => PlusGateSheet(feature: feature),
  );
  if (plans ?? false) {
    if (openPlans != null) {
      openPlans();
    } else if (context.mounted) {
      context.router.push(const PlusRoute());
    }
  }
  return false;
}

/// One feature, the price, and an equal-weight "Not now". The offer opens the
/// Plus screen, where the plans, terms and privacy are.
class PlusGateSheet extends StatelessWidget {
  const PlusGateSheet({super.key, required this.feature});
  final PlusFeature feature;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
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
            const SizedBox(height: LumSpace.lg),
            LumButton(
              label: PlusStrings.seePlans,
              kind: LumButtonKind.gold,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: LumSpace.md),
            LumButton(
              label: PlusStrings.notNow,
              kind: LumButtonKind.secondary,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
