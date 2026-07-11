import 'package:openbaptisthymnal/core/storage/storage_service.dart';
import 'package:openbaptisthymnal/features/onboarding/domain/seed_welcome_note.dart';

import 'release_notes.dart';

/// Drops a "what's new" tablet into the user's notes when they upgrade to a
/// build that has one they have not seen.
///
/// It is a real tablet, not a modal. Nobody reads a changelog dialog; they tap
/// it away to get to the app. A tablet sits in the list, can be read whenever,
/// can link straight to the thing it describes -- and can be deleted, which is
/// the whole difference between telling someone about a feature and interrupting
/// them.
///
/// **Deleted stays deleted.** The seeded-id list in shared-prefs is written the
/// moment a note is created, and it is the only thing consulted afterwards. The
/// app never asks whether the note is still in the database, so tidying it away
/// cannot resurrect it on the next launch. (That also rules out `upsertNote`,
/// which is an insert-or-update: pointed at a deleted row it would quietly
/// un-delete it.)
///
/// Idempotent and safe to call on every launch. Failures are swallowed -- a
/// changelog is not worth failing a cold start over.
Future<void> seedReleaseNotesIfNeeded({
  required StorageService storage,
  required CreateNoteFn createNote,
  List<ReleaseNote> releases = kReleaseNotes,
}) async {
  final seen = storage.getSeededReleaseNoteIds().toSet();
  final unseen = releases.where((r) => !seen.contains(r.id)).toList();
  if (unseen.isEmpty) return;

  // A brand-new install gets the welcome note, and everything in the app is new
  // to them -- handing them a back-catalogue of "what's new in 1.2" as well is
  // just clutter that grows with every release. So mark the history as seen
  // without writing it, and they will get the NEXT one like everybody else.
  final isFreshInstall = !storage.isOnboardingComplete() && seen.isEmpty;

  try {
    if (!isFreshInstall) {
      // Oldest first, so the newest release ends up newest in the tablet list.
      for (final release in unseen) {
        await createNote(
          title: release.title,
          contentMarkdown: release.body,
        );
      }
    }

    await storage.saveSeededReleaseNoteIds([
      ...seen,
      ...unseen.map((r) => r.id),
    ]);
  } catch (_) {
    // The ids stay unrecorded, so a launch that failed halfway retries next
    // time. Worst case that is a duplicate note, which the user can delete --
    // strictly better than a crash on startup.
  }
}
