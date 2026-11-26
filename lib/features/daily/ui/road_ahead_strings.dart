/// Words on the "Your road ahead" page and the road step of onboarding.
/// Plain English, denomination-neutral, short and warm.
abstract final class RoadAheadStrings {
  static const title = 'Your road ahead';
  static const doneTitle = 'Your whole road is ready';
  static const body =
      'Every stop on your reading year has a 3D landmark, from Genesis to '
      'Revelation. Tap one on the road and it spins on its podium.';
  static const doneBody =
      'All the landmarks are on this phone. Walk on, and tap any of them to '
      'watch it turn.';
  static const wifi =
      'Wi-Fi is a good idea. The download keeps going if you leave this page.';
  static const failed =
      'A few landmarks did not arrive. Check your connection and try again.';
  static const download = 'Download all';
  static const retry = 'Try again';
  static const allSet = 'All set';
  static const downloading = 'Downloading your landmarks';

  static String toDownload(int n) => '$n to download';
  static String included(int n) => '$n already included';
  static String caption(String title, int day) => '$title, day $day';
  static String progress(int done, int total) => '$done of $total';
  static String megabytes(String done, String total) => '$done of $total';
  static String remove(String size) => 'Remove downloads ($size)';
  static String heroLabel(int n) =>
      'A parade of $n landmarks from Genesis to Revelation';
}
