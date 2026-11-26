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
  static const markReadFailed = 'Could not save your reading. Try again.';
  static const backlinks = 'Notes linked to this verse';
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

  // Get more Bibles
  static const getMoreBibles = 'Get more Bibles';
  static const getMoreBiblesHint = 'Download more translations';
  static const included = 'Included';
  static const download = 'Download';
  static const remove = 'Remove';
  static const cancel = 'Cancel';
  static const bibleDownloadsIntro =
      'Downloaded Bibles stay on this phone and work offline. '
      'You can remove them any time.';
  static const catalogError =
      'We could not load the list of Bibles. Check your connection and try again.';
  static const catalogOffline =
      'You are offline. Showing the last list we saved.';
  static const downloadFailed = 'Download failed. Tap to try again.';
  static const downloadCorrupt =
      'That download did not check out. Tap to try again.';
  static const missingEditionNotice =
      'Your saved Bible is not on this phone, so you are reading the KJV.';
  static const getIt = 'Get it';
  static String removeTitle(String name) => 'Remove $name?';
  static const removeBody =
      'You can download it again later. Your notes and highlights stay.';
  static String downloading(int pct) => 'Downloading $pct%';
  static String sizeMb(int bytes) =>
      '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
