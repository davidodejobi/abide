/// Every user-facing string on the You tab, in one place until the ARB move
/// (DAO-131). Plain English, denomination-neutral.
abstract final class YouStrings {
  static const title = 'You';

  static const appearance = 'Appearance';
  static const theme = 'Theme';
  static const light = 'Light';
  static const dark = 'Dark';
  static const system = 'System';
  static const fontSize = 'Font size';
  static const fontSizeSample =
      'Amazing grace, how sweet the sound\nthat saved a wretch like me.';

  static const linking = 'Links';
  static const linkBible = 'Default Bible for links';
  static const linkHymnal = 'Default hymnal for links';
  static const followReading = 'Follow my reading';
  static const english = 'English';
  static const yoruba = 'Yorùbá';

  static const notes = 'Notes';
  static const manageTemplates = 'Manage templates';
  static const manageTemplatesHint = 'Pin, edit or add your own';
  static const voiceNotes = 'Voice notes';
  static const recordingQuality = 'Recording quality';
  static const qualityNote =
      'Higher quality sounds clearer but uses more storage.';

  static const road = 'Reading road';
  static const roadLandmarks = 'Road landmarks';
  static const roadDownloaded = 'Downloaded';
  static const roadNone = 'Not downloaded';
  static String roadPartial(int done, int total) => '$done of $total';
  static String roadSizeNote(String status, String size) => '$status, $size';

  static const about = 'About';
  static const version = 'Version';
  static const versionLoading = 'Loading';
  static const versionUnknown = 'Version unknown';
  static const bibleTranslations = 'Bible translations';
  static const sourcesLicenses = 'Sources and licenses';
  static const privacy = 'Privacy policy';
  static const terms = 'Terms of service';

  static const privacyUrl = 'https://abide-app-open.vercel.app/privacy.html';
  static const termsUrl = 'https://abide-app-open.vercel.app/terms.html';

  static String versionLabel(String v) => '$version $v';
  static String qualityHint(String sizeHint) => '$qualityNote $sizeHint.';
}
