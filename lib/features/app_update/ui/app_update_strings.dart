/// All user-facing copy for the app-update feature, in one place so it can
/// move to ARB files later.
abstract final class AppUpdateStrings {
  // Optional sheet (G-01)
  static const optionalTitle = 'Update available';
  static String optionalVersion(String v) => 'Version $v';
  static const optionalHeadline = 'A new version of Lumway is ready.';
  static const optionalBody =
      'You can update whenever you like. Reading is never blocked.';
  static const update = 'Update';
  static const later = 'Later';

  // Forced gate (G-02)
  static const forcedTitle = 'Update Lumway to keep reading';
  static const forcedBody =
      'This version can no longer talk to our servers. The update takes '
      'about a minute. Your road, streak and notes stay exactly as they are.';
  static const checkAgain = 'Check again';
  static const storeOpenFailed =
      'Could not open the store. Try again in a moment.';
  static const openAppStore = 'Open the App Store';
  static const openPlayStore = 'Open Google Play';
  static String forcedFootnote(String minVersion, String? checkedAtTime) =>
      'Needs version $minVersion or newer.'
      '${checkedAtTime == null ? '' : ' Last checked today at $checkedAtTime.'}';

  // Maintenance (G-05)
  static const maintenanceTitle = 'Lumway is resting for a short while';
  static const maintenanceBody =
      'We are updating our servers. Your Bible, hymns and notes still work '
      'on this phone.';
  static const keepReading = 'Keep reading';
  static const maintenanceFootnote =
      'Sync and church features return when we are back.';
}
