import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_edition.dart';

/// Lists every bundled Bible edition with its source + license credit. This is
/// how the app satisfies the CC BY-SA 4.0 attribution requirement for the
/// Biblica (Hausa/Igbo/Yorùbá) translations; public-domain editions are noted
/// too for transparency.
@RoutePage()
class BibleCreditsPage extends StatelessWidget {
  const BibleCreditsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Bible translations')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            'Abide bundles these Bible translations. Public-domain texts are '
            'free to use; the Biblica translations are used under the Creative '
            'Commons Attribution-ShareAlike 4.0 International License '
            '(CC BY-SA 4.0).',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 16),
          for (final e in kBibleEditions) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(PhosphorIcons.bookOpenText()),
              title: Text(
                e.displayName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(e.attribution),
            ),
            const Divider(height: 1),
          ],
          const SizedBox(height: 16),
          Text(
            'CC BY-SA 4.0: https://creativecommons.org/licenses/by-sa/4.0/',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}
