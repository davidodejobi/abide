import 'package:openbaptisthymnal/core/storage/storage_service.dart';

/// Signature of [TabletsRepository.createNote] — declared here so the seeder
/// can be unit-tested without spinning up the full Drift database.
typedef CreateNoteFn = Future<String> Function({
  String title,
  String contentMarkdown,
});

/// Creates the example "Welcome to your tablets" tablet the first time the
/// app starts up, so the Tablets tab opens with something concrete to read
/// and a working demo of `[[hymn:...]]` and `[[bible:...]]` wikilinks.
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

const _welcomeTitle = 'Welcome to your tablets';

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
Hi $greeting, welcome to your tablets.

A tablet is a single page you can write on. Sermon notes go here. Quiet thoughts. Quotes you want to keep. Anything you'd jot down in a paper notebook lives here, with the difference that you can tap a phrase and Abide takes you straight to it. Everything stays on your device, online or offline.

**Link to a hymn or a verse.** Type two square brackets and write what you want to point at. Try a hymn like [[hymn:hymn_0001]] (Holy, Holy, Holy), or a verse like [[bible:JHN.3.16]]. Tap any link and Abide jumps right to it. You can also link to another tablet by writing its title in brackets, like [[Sunday reflections]]. Open the linked tablet and this one shows up in its backlinks.

**Record a voice memo.** While the keyboard is up, tap the mic. The clip records right inside the tablet and plays back inline next time you open it. Handy for sermons when typing is too slow.

**Add a picture.** Snap or paste an image. A page from a book, a slide, a whiteboard from a service. It saves with the tablet and shows up the same way next time you open it.

**Organize with folders and tags.** Open the Tablets tab menu to create a folder, say "Sermons", "Hymns I love", "Prayer requests", then drop tablets into it. Tags work alongside folders. Add a tag like #grace or #thanksgiving and you can find every tablet with that thread later. A tablet sits in one folder and carries as many tags as you want.

When you're ready to make this your own, delete this tablet and start a fresh one. We left a couple more links to try: [[hymn:hymn_0004]] (All People That on Earth Do Dwell) and [[bible:PSA.23.1]] (Psalm 23). Welcome in.
''';
