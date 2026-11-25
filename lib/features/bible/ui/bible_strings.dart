import 'package:openbaptisthymnal/features/bible/model/bible_edition.dart';

/// Every user-facing string on the Bible reader, in one place until the ARB
/// move (DAO-131). Plain English, denomination-neutral.
abstract final class BibleStrings {
  static const back = 'Back';
  static const textSize = 'Text size';
  static const textSizeTitle = 'Text size';
  static const splitView = 'Split view';
  static const closeSplit = 'Close split view';
  static const swapPanes = 'Swap panes';
  static const change = 'Change';
  static const chooseVersion = 'Choose Bible version';
  static const bibleVersion = 'Bible version';
  static const onThisPhone = 'ON THIS PHONE';
  static const inUse = 'In use';
  static const close = 'Close';
  static const previous = 'Previous chapter';
  static const next = 'Next chapter';
  static const chooseChapter = 'Choose book and chapter';
  static const loadError = 'This edition could not be loaded';
  static const chapterLoadError = 'This chapter could not be loaded';
  static const retry = 'Try again';
  static const markRead = 'Mark read';
  static const addNote = 'Add note';
  static const share = 'Share';
  static const clearSelection = 'Clear selection';
  static const highlightPrefix = 'Highlight';
  static const removeHighlight = 'Remove highlight';
  static const untitledNote = 'Untitled tablet';
  static const sideBySide = 'Side by side';
  static const stacked = 'Stacked';

  // Pickers
  static const books = 'Books';
  static const oldTestament = 'OLD TESTAMENT';
  static const newTestament = 'NEW TESTAMENT';
  static const pickChapter = 'Pick a chapter';
  static const edition = 'EDITION';
  static const chooseBookAndChapter = 'Choose book and chapter';

  static String selected(int n) =>
      n == 1 ? '1 verse selected' : '$n verses selected';
  static String linkedFrom(String ref) => 'Linked from $ref';
  static String couldNotLoad(String e) => 'Could not load edition: $e';
  static String dayAndPassage(int day, String passage) =>
      'DAY $day · ${passage.toUpperCase()}';
  static String chapterOf(int i, int n) => 'CHAPTER $i OF $n';
  static String litDay(int n) => 'Lights day $n of your streak';

  static const _languageNames = {
    'en': 'English',
    'yo': 'Yorùbá',
    'ha': 'Hausa',
    'ig': 'Igbo',
  };

  /// "KJV" for the chip.
  static String versionCode(BibleEdition e) => e.versionCode.toUpperCase();

  /// "English · KJV" for pane headers and the edition rows.
  static String languageAndVersion(BibleEdition e) =>
      '${_languageNames[e.languageCode] ?? e.languageCode} · ${versionCode(e)}';
}
