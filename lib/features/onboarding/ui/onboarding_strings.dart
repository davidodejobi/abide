import 'package:openbaptisthymnal/features/bible/model/bible_edition.dart';

/// Every user-facing string in onboarding, in one place until the ARB move
/// (DAO-131). Plain English, denomination-neutral.
abstract final class OnboardingStrings {
  static const defaultDownloadLanguages = ['Yorùbá', 'Hausa', 'Igbo'];

  /// "Reading in Yorùbá, Hausa or Igbo? ..." under the English editions.
  static String downloadNote(List<String> languages) {
    final list = languages.length < 2
        ? languages.join()
        : '${languages.sublist(0, languages.length - 1).join(', ')} or ${languages.last}';
    return 'Reading in $list? Pick English for now and download your Bible '
        'in the app under Get more Bibles.';
  }

  static const back = 'Back';

  // Welcome
  static const welcomeCaps = 'WELCOME';
  static const welcomeTitle = 'One step a day.';
  static const freeAlwaysCaps = 'FREE, ALWAYS';
  static const welcomeBody =
      'Read a little of the Bible each day. Every day you read, you take one '
      'step along your road.';
  static const begin = 'Begin';

  // Language and Bible
  static const bibleTitle = 'Your Bible';
  static const bibleBody =
      'Both live on your phone, so you can read with no signal.';
  static const languageCaps = 'LANGUAGE';
  static const versionCaps = 'VERSION';
  static const moreSoon = 'More soon';
  static const moreSoonHint = 'More languages are coming';
  static const cont = 'Continue';

  // Plan
  static const planTitle = 'How far will you walk?';
  static const planLoadError = "Plans couldn't be loaded.";
  static const retry = 'Try again';
  static const yourGoalCaps = 'YOUR GOAL';
  static const finishLineCaps = 'FINISH LINE';

  // Road download
  static const roadTitle = 'Set up your road';
  static const roadBody =
      'Lumway will download the 3D landmarks for your reading road, so the '
      'journey looks its best.';
  static const roadSizeUnknown = 'It is a small download. Wi-Fi is a good idea.';
  static const downloadNow = 'Download now';
  static const later = 'Later';

  static String roadSize(String size) =>
      'It is about $size, so Wi-Fi is a good idea.';

  // Name
  static const nameTitle = 'What should we call you?';
  static const nameLabelCaps = 'FIRST NAME';
  static const nameHint = 'Your first name';
  static const nameHelp = 'Only on this phone. You can leave it empty.';
  static const startRoad = 'Start my road';
  static const finishError = 'Could not save your choices. Try again.';

  static String stepLabel(int step, int total) => '$step of $total';
  static String stepSemantics(int step, int total) =>
      'Step $step of $total';

  static String languageName(String code) => switch (code) {
        'en' => 'English',
        'yo' => 'Yorùbá',
        'ha' => 'Hausa',
        'ig' => 'Igbo',
        _ => code.toUpperCase(),
      };

  /// Edition title and one-line note for the version list. Unknown editions
  /// fall back to the catalogue name so a new translation never renders blank.
  static (String, String) editionText(BibleEdition e) => switch (e.id) {
        'en-kjv' => ('King James Version', 'KJV · the classic, from 1611'),
        'en-bsb' => ('Berean Standard Bible', 'BSB · modern and clear'),
        'en-asv' => (
            'American Standard Version',
            'ASV · careful and close to the text'
          ),
        'en-ylt' => ("Young's Literal Translation", 'YLT · word for word'),
        'yo-bmy' => ('Bíbélì Mímọ́', 'BMY · the classic, from 1900'),
        'yo-biblica' => ('Yorùbá Òde-Òní', 'Contemporary Yorùbá'),
        'ha-biblica' => ('Hausa Contemporary Bible', 'Biblica · modern Hausa'),
        'ig-biblica' => ('Igbo Contemporary Bible', 'Biblica · modern Igbo'),
        _ => (e.displayName, e.versionCode.toUpperCase()),
      };

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// "17 Dec"
  static String shortDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';
}
