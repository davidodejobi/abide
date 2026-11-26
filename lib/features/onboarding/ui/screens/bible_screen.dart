import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/widgets/lum_chip.dart';
import 'package:openbaptisthymnal/core/widgets/lum_group_card.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_edition.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_downloads_provider.dart';

import '../../domain/onboarding_defaults.dart';
import '../../providers/onboarding_provider.dart';
import '../onboarding_strings.dart';
import '../widgets/onboarding_frame.dart';

/// Step 1: reading language and Bible version. Language starts from the phone.
class BibleScreen extends ConsumerWidget {
  const BibleScreen({
    super.key,
    required this.step,
    required this.total,
    required this.onNext,
    required this.onBack,
  });

  final int step;
  final int total;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lum;
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final editions = editionsForLanguage(state.languageCode);
    final downloadNote = kIsWeb ? null : _downloadNote(ref);

    return OnboardingFrame(
      step: step,
      totalSteps: total,
      onBack: onBack,
      primaryLabel: OnboardingStrings.cont,
      onPrimary: onNext,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(OnboardingStrings.bibleTitle,
                style: LumText.title1.copyWith(color: c.textPrimary)),
          ),
          const SizedBox(height: LumSpace.sm),
          Text(OnboardingStrings.bibleBody,
              style: LumText.body.copyWith(color: c.textSecondary)),
          const SizedBox(height: LumSpace.xl),
          const _Caps(OnboardingStrings.languageCaps),
          const SizedBox(height: LumSpace.md),
          Wrap(
            spacing: LumSpace.sm,
            runSpacing: LumSpace.sm,
            children: [
              for (final code in onboardingLanguages())
                LumChip(
                  label: OnboardingStrings.languageName(code),
                  selected: code == state.languageCode,
                  onTap: () => notifier.setLanguage(code),
                ),
              const _MoreSoonChip(),
            ],
          ),
          const SizedBox(height: LumSpace.xl),
          const _Caps(OnboardingStrings.versionCaps),
          const SizedBox(height: LumSpace.md),
          LumGroupCard(
            child: Column(
              children: [
                for (var i = 0; i < editions.length; i++)
                  _EditionRow(
                    edition: editions[i],
                    selected: editions[i].id == state.editionId,
                    first: i == 0,
                    onTap: () => notifier.setEdition(editions[i].id),
                  ),
              ],
            ),
          ),
          if (downloadNote != null) ...[
            const SizedBox(height: LumSpace.md),
            Text(downloadNote,
                style: LumText.footnote.copyWith(color: c.textSecondary)),
          ],
        ],
      ),
    );
  }

  /// Points readers of other languages at the in-app downloads. Names come from
  /// the last saved catalog; before it has ever loaded, a fixed list is used.
  static String _downloadNote(WidgetRef ref) {
    final cached = ref.read(bibleCatalogSourceProvider).cached();
    final names = <String>[
      for (final e in cached?.editions ?? [])
        if (e.languageCode != 'en' && e.languageName.isNotEmpty) e.languageName,
    ].toSet().toList();
    return OnboardingStrings.downloadNote(
        names.isEmpty ? OnboardingStrings.defaultDownloadLanguages : names);
  }
}

class _Caps extends StatelessWidget {
  const _Caps(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(text,
      style: LumText.roadLabelCaps11.copyWith(color: context.lum.textSecondary));
}

class _MoreSoonChip extends StatelessWidget {
  const _MoreSoonChip();

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Semantics(
      label: OnboardingStrings.moreSoonHint,
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: LumSize.touchTarget),
        padding: const EdgeInsets.symmetric(horizontal: LumSpace.xl - 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(LumRadius.full),
          border: Border.all(color: c.borderStrong),
        ),
        child: Text(OnboardingStrings.moreSoon,
            style:
                LumText.subheadlineEmphasized.copyWith(color: c.textSecondary)),
      ),
    );
  }
}

class _EditionRow extends StatelessWidget {
  const _EditionRow({
    required this.edition,
    required this.selected,
    required this.first,
    required this.onTap,
  });

  final BibleEdition edition;
  final bool selected;
  final bool first;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    final (title, note) = OnboardingStrings.editionText(edition);
    return Semantics(
      button: true,
      selected: selected,
      label: '$title, $note',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: LumSize.rowMin + 8),
          padding: const EdgeInsets.symmetric(
              horizontal: LumSpace.lg, vertical: LumSpace.md),
          decoration: BoxDecoration(
            border: first
                ? null
                : Border(top: BorderSide(color: c.borderSubtle)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: LumText.bodyEmphasized
                            .copyWith(color: c.textPrimary)),
                    const SizedBox(height: 2),
                    Text(note,
                        style: LumText.footnote
                            .copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: LumSpace.md),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? c.buttonGoldTop : Colors.transparent,
                  border: selected
                      ? null
                      : Border.all(color: c.borderStrong, width: 1.5),
                ),
                child: selected
                    ? Icon(Icons.check_rounded,
                        size: 18, color: c.buttonOnGold)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
