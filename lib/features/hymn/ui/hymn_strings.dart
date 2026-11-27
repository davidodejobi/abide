/// Every user-facing string on the Songs screens, in one place until the ARB
/// move (DAO-131). Plain English, denomination-neutral.
abstract final class HymnStrings {
  static const songs = 'Songs';
  static const searchHint = 'Number, title or first line';
  static const clearSearch = 'Clear search';
  static const english = 'English';
  static const yoruba = 'Yorùbá';
  static const favourites = 'Favourites';
  static const favouritesTitle = 'Favourites';
  static const noFavourites = 'No favourites yet';
  static const noFavouritesBody = 'Tap the heart on any hymn to keep it here.';
  static const addFavourite = 'Add to favourites';
  static const removeFavourite = 'Remove from favourites';
  static const noResultsHint =
      'Try a hymn number, a title, or a few words from a line.';
  static const loadError = 'Songs could not be loaded';
  static const retry = 'Try again';
  static const back = 'Back';
  static const share = 'Share';
  static const splitView = 'Split view';
  static const closeSplit = 'Close split view';
  static const textSize = 'Text size';
  static const lyricSize = 'Lyric size';
  static const noTranslation = 'No translation found';
  static const chorus = 'CHORUS';
  static const change = 'Change';
  static const pickHymn = 'Pick a hymn';
  static const pickSearchHint = 'Search by number or title';
  static const noMatches = 'No matches.';
  static const pickAnother = 'Pick another';
  static const addLanguage = '+ Language';
  static const languagesTitle = 'Hymn languages';
  static const languagesClose = 'Close';

  static const scrollToTop = 'Scroll to top';
  static const scrollToBottom = 'Scroll to bottom';

  /// 'HYMNAL · ENGLISH', 'HYMNAL · ENGLISH AND YORÙBÁ', and so on.
  static String eyebrow(List<String> codes) {
    final names = [for (final c in codes) languageName(c).toUpperCase()];
    final list = names.length < 2
        ? names.join()
        : '${names.sublist(0, names.length - 1).join(', ')} AND ${names.last}';
    return 'HYMNAL · $list';
  }

  static String hymnCount(int n) => n == 1 ? '1 hymn' : '$n hymns';
  static String hymnEyebrow(int number) => 'HYMN $number · HYMNAL';
  static String stanzas(int n) => n == 1 ? '1 stanza' : '$n stanzas';
  static String noResults(String q) => 'No results for “$q”';
  static String notAvailable(String language) =>
      'No $language version of this hymn yet.';
  static String couldNotLoad(String e) => 'Could not load hymn: $e';

  static String languageName(String code) => switch (code) {
        'en' => english,
        'yo' => yoruba,
        _ => code,
      };
}
