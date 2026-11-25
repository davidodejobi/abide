import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/widgets/lum_button.dart';

import '../data/purchase_service.dart';
import '../plus_config.dart';
import '../providers/plus_providers.dart';

/// Pay for Plus access for a reader who could not afford it. A gift of access,
/// not a donation, so it is a store purchase. Never required, never guilt.
@RoutePage()
class SponsorPage extends HookConsumerWidget {
  const SponsorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lum;
    final busy = useState(false);
    final message = useState<String?>(null);

    Future<void> gift(SponsorGift g) async {
      if (busy.value) return;
      busy.value = true;
      message.value = null;
      final r = await ref.read(purchaseServiceProvider).sponsor(g);
      if (!context.mounted) return;
      busy.value = false;
      message.value =
          r == PurchaseOutcome.success ? PlusStrings.sponsorThanks : PlusStrings.failed;
    }

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
                  child: Text(PlusStrings.sponsorTitle,
                      style: LumText.largeTitle.copyWith(color: c.textPrimary)),
                ),
                const SizedBox(height: LumSpace.md),
                Text(PlusStrings.sponsorBody,
                    style: LumText.body.copyWith(color: c.textSecondary)),
                const SizedBox(height: LumSpace.xl),
                LumButton(
                  label:
                      '${PlusStrings.sponsorYear}, ${PlusConfig.sponsorYearPrice}',
                  kind: LumButtonKind.gold,
                  onPressed: busy.value ? null : () => gift(SponsorGift.year),
                ),
                const SizedBox(height: LumSpace.md),
                LumButton(
                  label:
                      '${PlusStrings.sponsorMonth}, ${PlusConfig.sponsorMonthPrice}',
                  kind: LumButtonKind.secondary,
                  onPressed: busy.value ? null : () => gift(SponsorGift.month),
                ),
                if (message.value != null) ...[
                  const SizedBox(height: LumSpace.lg),
                  Semantics(
                    liveRegion: true,
                    child: Text(message.value!,
                        style: LumText.callout.copyWith(color: c.textPrimary)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
