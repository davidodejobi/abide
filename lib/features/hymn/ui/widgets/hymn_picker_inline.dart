import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/theme/app_colors.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/features/hymn/providers/hymnal_provider.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/hymn_list_tile.dart';

/// Provider that loads all hymns for a specific language pack. Used by the
/// inline picker so the user can pick a hymn in either available language.
final hymnsForLanguageProvider =
    FutureProvider.family<List<_PickerHymnEntry>, String>((ref, language) async {
  final pack = await ref.read(hymnalRepositoryProvider).getLanguagePack(language);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.neutral100 : AppColors.neutral700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Pick a hymn',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: searchController,
            onChanged: (v) => query.value = v.trim().toLowerCase(),
            style: AppTextStyles.bodyMedium.copyWith(color: ink),
            decoration: InputDecoration(
              hintText: 'Search by number or title',
              prefixIcon: Icon(PhosphorIcons.magnifyingGlass(), size: 20),
              filled: true,
              fillColor:
                  isDark ? AppColors.neutral850 : AppColors.secondary50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: entriesAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Could not load hymns: $e')),
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
                return const Center(child: Text('No matches.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, i) {
                  final e = filtered[i];
                  return HymnListTile(
                    number: e.number.toString(),
                    title: e.title,
                    onTap: () => onSelected(e.id, language),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.neutral850 : AppColors.secondary50;
    final fg = isDark ? AppColors.neutral100 : AppColors.primaryDark;
    final selectedBg = isDark ? AppColors.neutral700 : Colors.white;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((o) {
          final selected = o == value;
          return GestureDetector(
            onTap: () => onChanged(o),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? selectedBg : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                o.toUpperCase(),
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
