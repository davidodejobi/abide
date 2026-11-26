import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/widgets/lum_button.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_catalog.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_downloads_provider.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';
import 'package:openbaptisthymnal/features/bible/ui/bible_strings.dart';
import 'package:openbaptisthymnal/features/settings/ui/widgets/you_rows.dart';

/// "Get more Bibles": the catalog grouped by language, each row showing size
/// and a Download / Downloading / Remove action. Bundled editions read
/// "Included". Hidden on web, where there is nowhere to keep a download.
@RoutePage()
class MoreBiblesPage extends ConsumerWidget {
  const MoreBiblesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lum;
    final state = ref.watch(bibleCatalogProvider);
    final catalog = state.catalog;

    final Widget body;
    if (catalog == null) {
      body = state.failed
          ? _ErrorView(
              onRetry: () => ref.read(bibleCatalogProvider.notifier).refresh())
          : Center(child: CircularProgressIndicator(color: c.textSecondary));
    } else {
      final groups = <String, List<BibleCatalogEntry>>{};
      for (final e in catalog.editions) {
        (groups[e.languageName] ??= []).add(e);
      }
      body = RefreshIndicator(
        onRefresh: ref.read(bibleCatalogProvider.notifier).refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
              LumSize.screenGutter, LumSpace.sm, LumSize.screenGutter, 32),
          children: [
            Text(BibleStrings.bibleDownloadsIntro,
                style: LumText.subheadline.copyWith(color: c.textSecondary)),
            if (state.failed)
              Padding(
                padding: const EdgeInsets.only(top: LumSpace.md),
                child: Text(BibleStrings.catalogOffline,
                    style: LumText.footnoteEmphasized
                        .copyWith(color: c.textPrimary)),
              ),
            for (final g in groups.entries) ...[
              YouSectionLabel(g.key),
              YouGroup(children: [
                for (final e in g.value) _BibleRow(entry: e),
              ]),
            ],
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text(BibleStrings.getMoreBibles)),
      body: kIsWeb ? const SizedBox.shrink() : body,
    );
  }
}

class _BibleRow extends ConsumerWidget {
  const _BibleRow({required this.entry});

  final BibleCatalogEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lum;
    final installed = ref
        .watch(installedBiblesProvider)
        .any((e) => e.id == entry.id);
    final status = ref.watch(bibleDownloadsProvider)[entry.id];
    final downloads = ref.read(bibleDownloadsProvider.notifier);

    final String label;
    final VoidCallback? onTap;
    var filled = false;
    if (entry.bundled) {
      label = BibleStrings.included;
      onTap = null;
    } else if (status != null && status.active) {
      label = BibleStrings.downloading((status.progress * 100).round());
      onTap = null;
    } else if (installed) {
      label = BibleStrings.remove;
      onTap = () => _confirmRemove(context, downloads);
    } else {
      label = status == null ? BibleStrings.download : BibleStrings.retry;
      filled = true;
      onTap = () => downloads.download(entry);
    }

    final subtitle = status?.error == null
        ? '${entry.abbreviation} · ${BibleStrings.sizeMb(entry.sizeBytes)}'
        : status!.error == BibleDownloadError.corrupt
            ? BibleStrings.downloadCorrupt
            : BibleStrings.downloadFailed;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: LumSpace.lg, vertical: LumSpace.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name,
                    style:
                        LumText.bodyEmphasized.copyWith(color: c.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: LumText.footnote.copyWith(color: c.textSecondary)),
                if (status != null && status.active) ...[
                  const SizedBox(height: LumSpace.sm),
                  LinearProgressIndicator(
                    value: status.progress == 0 ? null : status.progress,
                    color: c.bgPrimary,
                    backgroundColor: c.borderSubtle,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: LumSpace.md),
          Semantics(
            button: onTap != null,
            label: '$label, ${entry.name}',
            excludeSemantics: true,
            onTap: onTap,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: LumSpace.md),
                decoration: filled
                    ? BoxDecoration(
                        color: c.bgPrimary,
                        borderRadius: BorderRadius.circular(LumRadius.full))
                    : null,
                child: Text(label,
                    style: LumText.footnoteEmphasized.copyWith(
                        color: filled ? c.textOnPrimary : c.textSecondary)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(
      BuildContext context, BibleDownloadsNotifier downloads) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(BibleStrings.removeTitle(entry.name)),
        content: const Text(BibleStrings.removeBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(BibleStrings.cancel)),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(BibleStrings.remove)),
        ],
      ),
    );
    if (ok == true) await downloads.remove(entry.id);
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LumSize.screenGutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(BibleStrings.catalogError,
                textAlign: TextAlign.center,
                style: LumText.body.copyWith(color: c.textSecondary)),
            const SizedBox(height: LumSpace.lg),
            LumButton(label: BibleStrings.retry, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
