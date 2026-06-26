import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/features/bible/domain/bible_link_resolver.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';
import 'package:openbaptisthymnal/features/bible/providers/pending_verse_highlight_provider.dart';

/// Resolves a `[[bible:...]]` link and opens the reader at that passage,
/// flashing the linked verse(s). Shared by the editor's inline tap handler and
/// the links sheet so the two never drift. [targetKey] is e.g. `JHN.3.16` or
/// `JHN.3.16-18`; [editionPin] is the optional `:en-bsb` suffix.
Future<void> openBibleLink(
  BuildContext context,
  WidgetRef ref, {
  required String targetKey,
  String? editionPin,
}) async {
  final target = await ref
      .read(bibleLinkResolverProvider)
      .resolve(targetKey, editionPin: editionPin);
  if (target == null || !context.mounted) return;

  final positionNotifier = ref.read(bibleReadingPositionProvider.notifier);
  final currentEdition = ref.read(bibleReadingPositionProvider).editionId;
  if (target.editionId != currentEdition) {
    positionNotifier.setEdition(target.editionId);
  }
  positionNotifier.openChapter(target.bookCode, target.chapter);

  if (target.highlightFromVerse != null) {
    ref.read(pendingVerseHighlightProvider.notifier).request(
          PendingVerseHighlight(
            editionId: target.editionId,
            bookCode: target.bookCode,
            chapter: target.chapter,
            fromVerse: target.highlightFromVerse!,
            toVerse: target.highlightToVerse ?? target.highlightFromVerse!,
          ),
        );
  }
  if (target.toastMessage != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(target.toastMessage!)),
    );
  }
  context.router.push(const BibleReaderRoute());
}
