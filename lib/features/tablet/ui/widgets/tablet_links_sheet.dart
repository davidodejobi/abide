import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/features/hymn/ui/viewmodels/hymns_viewmodel.dart';
import 'package:openbaptisthymnal/features/tablet/domain/parse_links.dart';
import 'package:openbaptisthymnal/features/tablet/providers/tablets_providers.dart';

/// Bottom sheet showing a note's outgoing links (parsed live from its markdown)
/// and its backlinks (other notes that link to it by title).
class NoteLinksSheet extends ConsumerWidget {
  const NoteLinksSheet({
    super.key,
    required this.markdown,
    required this.title,
  });

  /// The current editor body, parsed for `[[...]]` tokens.
  final String markdown;

  /// The current note title, used to resolve backlinks.
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final outgoing = parseLinks(markdown);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionHeader('Links', count: outgoing.length),
            if (outgoing.isEmpty)
              const _Hint('Use [[Note Title]], [[hymn:hymn_0001]] or '
                  '[[bible:JHN.3.16]] to link.')
            else
              ...outgoing.map((l) => _OutgoingTile(link: l)),
            const SizedBox(height: 20),
            _BacklinksSection(title: title),
            if (title.trim().isEmpty)
              const _Hint('Give this note a title to receive backlinks.'),
            const SizedBox(height: 8),
            Text(
              'Tip: backlinks match on title.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutgoingTile extends ConsumerWidget {
  const _OutgoingTile({required this.link});

  final ParsedLink link;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (link.type) {
      case NoteLinkType.hymn:
        final hymns = ref.watch(hymnsViewModelProvider).valueOrNull;
        final hymn =
            hymns?.where((h) => h.id == link.targetKey).firstOrNull;
        final label = hymn == null
            ? link.targetKey
            : '#${hymn.number}  ${hymn.title}';
        return _LinkTile(
          icon: Icons.library_music_outlined,
          label: label,
          onTap: () =>
              context.router.push(HymnDetailRoute(hymnId: link.targetKey)),
        );
      case NoteLinkType.bible:
        return _LinkTile(
          icon: Icons.menu_book_outlined,
          label: link.targetKey,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bible reading is coming soon.')),
            );
          },
        );
      case NoteLinkType.note:
        final notes = ref.watch(tabletsListProvider).valueOrNull;
        final match = notes
            ?.where((n) => n.title.toLowerCase() == link.targetKey.toLowerCase())
            .firstOrNull;
        return _LinkTile(
          icon: Icons.description_outlined,
          label: link.display,
          trailing: match == null
              ? const Text('not found', style: TextStyle(fontSize: 12))
              : null,
          onTap: match == null
              ? null
              : () => context.router.push(TabletEditorRoute(noteId: match.id)),
        );
    }
  }
}

class _BacklinksSection extends ConsumerWidget {
  const _BacklinksSection({required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (title.trim().isEmpty) {
      return const _SectionHeader('Backlinks', count: 0);
    }
    final backlinks = ref.watch(backlinksProvider(title)).valueOrNull ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader('Backlinks', count: backlinks.length),
        if (backlinks.isEmpty)
          const _Hint('No other notes link here yet.')
        else
          ...backlinks.map(
            (n) => _LinkTile(
              icon: Icons.subdirectory_arrow_left,
              label: n.title.isEmpty ? 'Untitled' : n.title,
              onTap: () =>
                  context.router.push(TabletEditorRoute(noteId: n.id)),
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label, {required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label  ·  $count',
        style: theme.textTheme.titleSmall?.copyWith(
          fontFamily: 'Geist',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(icon, size: 20),
      title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: trailing,
      enabled: onTap != null,
      onTap: onTap,
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
      ),
    );
  }
}
