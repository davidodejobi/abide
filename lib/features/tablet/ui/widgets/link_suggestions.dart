import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';
import 'package:openbaptisthymnal/features/hymn/ui/viewmodels/hymns_viewmodel.dart';
import 'package:openbaptisthymnal/features/tablet/domain/bible_autocomplete.dart';
import 'package:openbaptisthymnal/features/tablet/providers/tablets_providers.dart';

/// Floating autocomplete list for `[[` link tokens. Matches existing notes by
/// title, hymns by number/title, and Bible references by book / chapter / verse
/// when the query starts with `bible:`.
class LinkSuggestions extends ConsumerWidget {
  const LinkSuggestions({
    super.key,
    required this.query,
    required this.currentNoteId,
    required this.onSelected,
  });

  final String query;
  final String? currentNoteId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final q = query.trim().toLowerCase();

    final notes = (ref.watch(tabletsListProvider).valueOrNull ?? [])
        .where((n) => n.id != currentNoteId && n.title.trim().isNotEmpty)
        .where((n) => q.isEmpty || n.title.toLowerCase().contains(q))
        .take(4)
        .toList();

    final hymns = (ref.watch(hymnsViewModelProvider).valueOrNull ?? [])
        .where((h) => h.id != null)
        .where((h) =>
            q.isEmpty ||
            h.number.toString() == q ||
            h.title.toLowerCase().contains(q))
        .take(4)
        .toList();

    final bibleManifestAsync =
        q.startsWith('bible:') ? ref.watch(bibleManifestProvider('en-kjv')) : null;
    final bible = switch (bibleManifestAsync) {
      AsyncData(:final value) => bibleAutocompleteSuggestions(value, query),
      _ => <BibleSuggestion>[],
    };

    if (notes.isEmpty && hymns.isEmpty && bible.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: theme.colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 240),
        child: ListView(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          children: [
            for (final n in notes)
              _Row(
                icon: Icons.description_outlined,
                label: n.title,
                onTap: () => onSelected(n.title),
              ),
            for (final h in hymns)
              _Row(
                icon: Icons.library_music_outlined,
                label: '#${h.number}  ${h.title}',
                onTap: () => onSelected('hymn:${h.id}'),
              ),
            for (final b in bible)
              _Row(
                icon: b.isVerse
                    ? Icons.format_quote_outlined
                    : b.isChapter
                        ? Icons.chrome_reader_mode_outlined
                        : Icons.menu_book_outlined,
                label: b.label,
                onTap: () => onSelected(b.token),
              ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20),
      title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }
}
