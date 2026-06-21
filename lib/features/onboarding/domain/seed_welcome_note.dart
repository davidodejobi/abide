import 'package:openbaptisthymnal/core/storage/storage_service.dart';

/// Signature of [TabletsRepository.createNote] — declared here so the seeder
/// can be unit-tested without spinning up the full Drift database.
typedef CreateNoteFn = Future<String> Function({
  String title,
  String contentMarkdown,
});

/// Creates the example "Welcome to your notes" note the first time a user
/// completes onboarding, so the notes tab isn't empty and the user has a
/// concrete demo of `[[hymn:...]]` and `[[bible:...]]` wikilinks they can tap.
///
/// Idempotent and safe to call more than once: a `welcome_note_seeded` flag in
/// shared-prefs guards against duplicates. Failures are swallowed — if the
/// seed throws (e.g. DB hiccup), onboarding still finishes cleanly.
Future<void> seedWelcomeNoteIfNeeded({
  required StorageService storage,
  required CreateNoteFn createNote,
  String? userName,
}) async {
  if (storage.isWelcomeNoteSeeded()) return;

  final greeting = _firstName(userName) ?? 'there';
  final body = _welcomeBody(greeting);

  try {
    await createNote(
      title: _welcomeTitle,
      contentMarkdown: body,
    );
    await storage.saveWelcomeNoteSeeded(true);
  } catch (_) {
    // Onboarding completion shouldn't fail just because seeding tripped — try
    // again on a future launch (the flag stays false).
  }
}

const _welcomeTitle = 'Welcome to your notes';

String? _firstName(String? full) {
  final trimmed = full?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  final first = trimmed.split(RegExp(r'\s+')).first;
  return first.isEmpty ? null : first;
}

/// The hymn ids and verse refs used here are deliberately well-known and
/// present in the shipped EN + YO packs (hymn_0001 = Holy, Holy, Holy;
/// hymn_0004 = All People That on Earth Do Dwell) and in both Bible editions
/// (JHN.3.16, PSA.23.1).
String _welcomeBody(String greeting) => '''
Hi $greeting — this is where your notes live. Use this page for a sermon, a quiet thought, a quote you want to keep, or anything in between. Everything you write stays on your device and goes with you, online or offline.

**Link to a hymn or a verse.** Type two square brackets and write what you want to point at: a hymn like [[hymn:hymn_0001]] (Holy, Holy, Holy) or a verse like [[bible:JHN.3.16]]. Tap any link and Abide jumps right to it. You can also link to another note by writing its title in brackets, like [[Sunday reflections]] — open the linked note and you'll see this one in its backlinks.

**Record a voice memo.** While the keyboard is up, tap the mic to record audio right inside the note — useful for sermons when typing is too slow. The clip plays back inline whenever you reopen the note.

**Add a picture.** Snap or paste an image to attach a photo of a page, a slide, or a whiteboard from a service. It saves with the note and shows up the same way next time you open it.

**Organize with folders and tags.** Open the notes tab menu to create a folder for "Sermons", "Hymns I love", or "Prayer requests", then drop notes into it. Tags work alongside folders — give a note tags like #grace or #thanksgiving and you'll find every note with that thread later. A note can sit in one folder and carry as many tags as you want.

When you're ready to make this your own, delete this note and start a fresh one. We left a couple more links to try: [[hymn:hymn_0004]] (All People That on Earth Do Dwell) and [[bible:PSA.23.1]] (Psalm 23). Welcome in.
''';
