import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/providers/service_providers.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/widgets/lum_button.dart';

import '../data/purchase_service.dart';
import '../plus_config.dart';
import '../providers/plus_providers.dart';

/// Everything Plus adds, the price before the ask, and the way out.
@RoutePage()
class PlusPage extends HookConsumerWidget {
  const PlusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lum;
    final isPlus = ref.watch(plusProvider.select((e) => e.isPlus));
    final plan = useState(PlusPlan.annual);
    final busy = useState(false);
    final message = useState<String?>(null);

    Future<void> run(Future<PurchaseOutcome> Function() action,
        {String? okMessage}) async {
      if (busy.value) return;
      busy.value = true;
      message.value = null;
      final r = await action();
      if (!context.mounted) return;
      busy.value = false;
      message.value = switch (r) {
        PurchaseOutcome.success => okMessage,
        PurchaseOutcome.nothingToRestore => PlusStrings.nothingToRestore,
        PurchaseOutcome.failed => PlusStrings.failed,
      };
    }

    final notifier = ref.read(plusProvider.notifier);
    return Scaffold(
      backgroundColor: c.bgPage,
      appBar: AppBar(
        backgroundColor: c.bgPage,
        elevation: 0,
        iconTheme: IconThemeData(color: c.textPrimary),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(LumSize.screenGutter, 0,
                  LumSize.screenGutter, LumSpace.xxl),
              children: [
                Semantics(
                  header: true,
                  child: Text(PlusStrings.title,
                      style: LumText.largeTitle.copyWith(color: c.textPrimary)),
                ),
                const SizedBox(height: LumSpace.md),
                Text(PlusStrings.freePromise,
                    style: LumText.body.copyWith(color: c.textSecondary)),
                const SizedBox(height: LumSpace.xl),
                Text(PlusStrings.included.toUpperCase(),
                    style: LumText.footnoteEmphasized
                        .copyWith(color: c.textSecondary, letterSpacing: 0.6)),
                const SizedBox(height: LumSpace.sm),
                for (final f in PlusFeature.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: LumSpace.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f.title,
                            style: LumText.bodyEmphasized
                                .copyWith(color: c.textPrimary)),
                        Text(f.blurb,
                            style: LumText.subheadline
                                .copyWith(color: c.textSecondary)),
                      ],
                    ),
                  ),
                const SizedBox(height: LumSpace.xl),
                if (isPlus)
                  Text(PlusStrings.youHavePlus,
                      style: LumText.headline.copyWith(color: c.textPrimary))
                else ...[
                  _PlanTile(
                    label: PlusStrings.annual,
                    price: '${PlusConfig.annualPrice} a year',
                    badge: PlusStrings.bestValue,
                    selected: plan.value == PlusPlan.annual,
                    onTap: () => plan.value = PlusPlan.annual,
                  ),
                  const SizedBox(height: LumSpace.sm),
                  _PlanTile(
                    label: PlusStrings.monthly,
                    price: '${PlusConfig.monthlyPrice} a month',
                    selected: plan.value == PlusPlan.monthly,
                    onTap: () => plan.value = PlusPlan.monthly,
                  ),
                  const SizedBox(height: LumSpace.md),
                  Text(
                    plan.value == PlusPlan.annual
                        ? PlusStrings.thenPrice(PlusConfig.annualPrice, 'year')
                        : PlusStrings.thenPrice(PlusConfig.monthlyPrice, 'month'),
                    style: LumText.footnote.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: LumSpace.lg),
                  LumButton(
                    label: PlusStrings.startTrial,
                    kind: LumButtonKind.gold,
                    onPressed: busy.value
                        ? null
                        : () => run(() => notifier.startTrial(plan.value),
                            okMessage: PlusStrings.youHavePlus),
                  ),
                ],
                if (message.value != null) ...[
                  const SizedBox(height: LumSpace.md),
                  Semantics(
                    liveRegion: true,
                    child: Text(message.value!,
                        style: LumText.footnote.copyWith(color: c.textSecondary)),
                  ),
                ],
                const SizedBox(height: LumSpace.lg),
                Wrap(
                  spacing: LumSpace.lg,
                  children: [
                    _Link(PlusStrings.restore,
                        () => run(notifier.restore, okMessage: PlusStrings.restored)),
                    _Link(PlusStrings.sponsorRow,
                        () => context.router.push(const SponsorRoute())),
                    _Link(
                        PlusStrings.terms,
                        () => ref
                            .read(urlLauncherServiceProvider)
                            .openUrl(PlusConfig.termsUrl)),
                    _Link(
                        PlusStrings.privacy,
                        () => ref
                            .read(urlLauncherServiceProvider)
                            .openUrl(PlusConfig.privacyUrl)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.label,
    required this.price,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final String price;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $price',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: LumSize.rowMin),
          padding: const EdgeInsets.all(LumSpace.lg),
          decoration: BoxDecoration(
            color: c.bgSurface,
            borderRadius: BorderRadius.circular(LumRadius.lg),
            border: Border.all(
                color: selected ? c.borderFocus : c.borderSubtle,
                width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: LumText.bodyEmphasized
                            .copyWith(color: c.textPrimary)),
                    Text(price,
                        style: LumText.subheadline
                            .copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
              if (badge != null)
                Text(badge!,
                    style: LumText.footnoteEmphasized
                        .copyWith(color: c.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onTap,
        child: Text(label,
            style: LumText.subheadline.copyWith(color: context.lum.textSecondary)),
      );
}
