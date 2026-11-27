import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/widgets/lum_circle_button.dart';
import 'package:openbaptisthymnal/core/widgets/lum_group_card.dart';
import 'package:openbaptisthymnal/features/hymn/providers/enabled_hymn_languages_provider.dart';
import 'package:openbaptisthymnal/features/hymn/providers/hymnal_provider.dart';
import 'package:openbaptisthymnal/features/hymn/ui/hymn_strings.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

final _packCountProvider = FutureProvider.family<int, String>((ref, code) async {
  final pack = await ref.read(hymnalRepositoryProvider).getLanguagePack(code);
  return pack.hymns.length;
});

/// "Hymn languages": every bundled pack with its hymn count and an on/off
/// switch. Songs shows only the languages switched on here.
Future<void> showHymnLanguagesSheet(BuildContext context) {
  final c = context.lum;
  return showModalBottomSheet<void>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: c.bgElevated,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    builder: (_) => const HymnLanguagesSheet(),
  );
}

class HymnLanguagesSheet extends ConsumerWidget {
  const HymnLanguagesSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lum;
    final enabled = ref.watch(enabledHymnLanguagesProvider);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(LumSize.screenGutter, LumSpace.md,
            LumSize.screenGutter, LumSpace.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: c.borderStrong,
                  borderRadius: BorderRadius.circular(LumRadius.full),
                ),
              ),
            ),
            const SizedBox(height: LumSpace.md),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(HymnStrings.languagesTitle,
                        style: LumText.title1.copyWith(color: c.textPrimary)),
                  ),
                ),
                LumCircleButton(
                  icon: PhosphorIcons.x(),
                  label: HymnStrings.languagesClose,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: LumSpace.lg),
            LumGroupCard(
              child: Column(
                children: [
                  for (final code in kHymnPacks)
                    _LanguageRow(
                      code: code,
                      on: enabled.contains(code),
                      // The last language on can't be turned off.
                      locked: enabled.length == 1 && enabled.contains(code),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageRow extends ConsumerWidget {
  const _LanguageRow(
      {required this.code, required this.on, required this.locked});

  final String code;
  final bool on;
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lum;
    final count = ref.watch(_packCountProvider(code)).valueOrNull;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: LumSpace.lg, vertical: LumSpace.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(HymnStrings.languageName(code),
                    style: LumText.body.copyWith(color: c.textPrimary)),
                if (count != null)
                  Text(HymnStrings.hymnCount(count),
                      style:
                          LumText.footnote.copyWith(color: c.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: on,
            onChanged: locked
                ? null
                : (v) => ref
                    .read(enabledHymnLanguagesProvider.notifier)
                    .setEnabled(code, v),
          ),
        ],
      ),
    );
  }
}
