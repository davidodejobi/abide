import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/features/hymn/domain/hymn_link_resolver.dart';
import 'package:openbaptisthymnal/features/hymn/providers/hymnal_provider.dart';

/// Resolves a `[[hymn:...]]` link and opens the hymn page. Shared by the
/// editor's inline tap handler and the links sheet so the two never drift.
Future<void> openHymnLink(
  BuildContext context,
  WidgetRef ref, {
  required String targetKey,
  String? editionPin,
}) async {
  final target = await ref
      .read(hymnLinkResolverProvider)
      .resolve(targetKey, editionPin: editionPin);
  if (target == null || !context.mounted) return;
  // The hymn detail page reads `languageProvider` to pick its pack, so set it
  // before pushing so the resolved edition is the one that opens.
  ref.read(languageProvider.notifier).state = target.editionId;
  if (target.toastMessage != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(target.toastMessage!)),
    );
  }
  context.router.push(HymnDetailRoute(hymnId: target.hymnId));
}
