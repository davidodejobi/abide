import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/features/hymn/ui/hymn_strings.dart';
import 'package:openbaptisthymnal/features/hymn/providers/hymnal_provider.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/hymn_list_tile.dart';

/// Provider that loads all hymns for a specific language pack. Used by the
/// inline picker so the user can pick a hymn in either available language.
final hymnsForLanguageProvider =
    FutureProvider.family<List<_PickerHymnEntry>, String>(
        (ref, language) async {
  final pack =
      await ref.read(hymnalRepositoryProvider).getLanguagePack(language);
  final entries = pack.hymns.entries
      .map((e) => _PickerHymnEntry(
            id: e.key,
            number: e.value.number,
            title: e.value.title,
          ))
      .toList()
    ..sort((a, b) => a.number.compareTo(b.number));
  return entries;
});

class _PickerHymnEntry {
  const _PickerHymnEntry({
    required this.id,
    required this.number,
    required this.title,
  });

  final String id;
  final int number;
  final String title;
}

/// Inline hymn picker rendered inside a split-view pane. Lets the user search
/// and choose any hymn to display in the secondary pane.
class HymnPickerInline extends HookConsumerWidget {
  const HymnPickerInline({
    super.key,
    required this.language,
    required this.onSelected,
    this.onLanguageChanged,
    this.availableLanguages = const ['en', 'yo'],
  });

  final String language;
  final void Function(String hymnId, String language) onSelected;
  final ValueChanged<String>? onLanguageChanged;
  final List<String> availableLanguages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final query = useState('');
    final entriesAsync = ref.watch(hymnsForLanguageProvider(language));
    final c = context.lum;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              LumSpace.lg, LumSpace.sm, LumSpace.lg, LumSpace.md),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(HymnStrings.pickHymn,
                      style: LumText.title3.copyWith(color: c.textPrimary)),
                ),
              ),
              if (onLanguageChanged != null && availableLanguages.length > 1)
                _LanguageSwitch(
                  value: language,
                  options: availableLanguages,
                  onChanged: onLanguageChanged!,
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: LumSpace.lg),
          child: TextField(
            controller: searchController,
            onChanged: (v) => query.value = v.trim().toLowerCase(),
            style: LumText.body.copyWith(color: c.textPrimary),
            decoration: InputDecoration(
              hintText: HymnStrings.pickSearchHint,
              hintStyle: LumText.body.copyWith(color: c.textSecondary),
              prefixIcon: Icon(PhosphorIcons.magnifyingGlass(), size: 20),
              filled: true,
              fillColor: c.bgSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(LumRadius.full),
                borderSide: BorderSide(color: c.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(LumRadius.full),
                borderSide: BorderSide(color: c.borderSubtle),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: LumSpace.md),
        Expanded(
          child: entriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(HymnStrings.loadError,
                  style: LumText.body.copyWith(color: c.textSecondary)),
            ),
            data: (entries) {
              final q = query.value;
              final filtered = q.isEmpty
                  ? entries
                  : entries.where((e) {
                      final numStr = e.number.toString().padLeft(3, '0');
                      return e.title.toLowerCase().contains(q) ||
                          numStr.contains(q) ||
                          e.number.toString().contains(q);
                    }).toList();
              if (filtered.isEmpty) {
                return Center(
                  child: Text(HymnStrings.noMatches,
                      style: LumText.body.copyWith(color: c.textSecondary)),
                );
              }
              return ListView.builder(
                padding:
                    const EdgeInsets.fromLTRB(LumSpace.md, 0, LumSpace.md, 120),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final e = filtered[i];
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.bgSurface,
                      borderRadius: HymnListTile.edgeRadius(i, filtered.length),
                    ),
                    child: HymnListTile(
                      number: e.number.toString(),
                      title: e.title,
                      showDivider: i < filtered.length - 1,
                      onTap: () => onSelected(e.id, language),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LanguageSwitch extends StatelessWidget {
  const _LanguageSwitch({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Container(
      padding: const EdgeInsets.all(LumSpace.xs),
      decoration: BoxDecoration(
        color: c.bgSurface,
        borderRadius: BorderRadius.circular(LumRadius.full),
        border: Border.all(color: c.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((o) {
          final selected = o == value;
          return Semantics(
            button: true,
            selected: selected,
            label: HymnStrings.languageName(o),
            excludeSemantics: true,
            onTap: () => onChanged(o),
            child: GestureDetector(
              onTap: () => onChanged(o),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: LumMotion.fast,
                constraints: const BoxConstraints(
                    minWidth: LumSize.touchTarget - 8, minHeight: 40),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: LumSpace.md),
                decoration: BoxDecoration(
                  color: selected ? c.bgPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(LumRadius.full),
                ),
                child: Text(
                  o.toUpperCase(),
                  style: LumText.footnoteEmphasized.copyWith(
                      color: selected ? c.textOnPrimary : c.textPrimary),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
