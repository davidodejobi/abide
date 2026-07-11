/// One release's "what's new" tablet.
class ReleaseNote {
  const ReleaseNote({
    required this.id,
    required this.title,
    required this.body,
  });

  /// Persisted in shared-prefs once the note is created, so it decides forever
  /// whether this release note has been shown. **Never change or reuse an id.**
  /// Changing one re-seeds the note for everyone, including the people who
  /// already deleted it -- which is precisely the thing this feature promises
  /// not to do.
  final String id;

  final String title;

  /// Markdown. Wikilinks work here exactly as in any other tablet, so a release
  /// note can point straight at the thing it is describing.
  final String body;
}

/// Every release note the app has ever shipped, oldest first.
///
/// To announce a feature: append an entry. Users who already have the app get
/// the note on their next launch; a brand-new install gets none of the back
/// catalogue (see `seed_release_notes.dart`).
///
/// Keep it short and concrete. This lands in someone's own notebook, next to
/// their sermon notes -- it should read like a note from a person, not a
/// changelog.
const kReleaseNotes = <ReleaseNote>[
  ReleaseNote(
    id: 'release-today-tab',
    title: 'New in Abide: Today, streaks and reading plans',
    body: '''
There is a new **Today** tab, first in the row at the bottom. It is there to give the day a place to start.

**Pick a reading plan.** The New Testament in 90 days, the Psalms in a month, or the whole Bible in a year. Tap *Choose a plan* and you will get a passage each day. Days are balanced by how much there is to read, not by chapter count, so a day in Psalms is not ten times longer than the one before it.

**Your streak.** Read a day, mark it read, and it counts. Tap the streak to see every day you have read laid out on a calendar. Missing one day a week will not break it — two in a row will. It is a record of turning up, not a stick to beat yourself with.

**Fell behind?** Nothing is skipped. Today always shows the oldest day you have not read, so you pick up where you left off rather than losing the days you missed. You can read several in one sitting and catch right up.

**Change plans freely.** Your place in the old one is kept. Come back to it whenever and it resumes where you were.

A few other things in this release: chapters in the Bible now turn with a swipe, and links like [[bible:PSA.23.1]] open right where they should.

You can delete this tablet whenever you like — it will not come back.
''',
  ),
];
