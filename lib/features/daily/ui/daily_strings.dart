import 'package:openbaptisthymnal/core/utils/time_greeting.dart';

/// Every user-facing string on the Today tab and the streak page, in one place
/// until the ARB move (DAO-131). Plain English, denomination-neutral.
abstract final class DailyStrings {
  static const dayLabel = 'DAY';
  static const todaysReading = "Today's reading";
  static const startReading = 'Start reading';
  static const writeNote = 'Write a note';
  static const readAhead = 'Read ahead';
  static const allDays = 'All days';
  static const changePlan = 'Change plan';
  static const choosePlan = 'Choose a plan';
  static const chooseAnotherPlan = 'Choose another plan';
  static const noPlanCaps = 'No plan yet';
  static const noPlanTitle = 'Pick a road to walk';
  static const noPlanBody =
      'Choose a reading plan. Your traveller starts at stop 1 and walks one '
      'stop each day you read.';
  static const planCompleteTitle = 'Plan complete';
  static const planCompleteBody =
      'You read every day of it. Start another when you are ready.';
  static const loadError = "Today's reading couldn't be loaded.";
  static const tomorrow = 'Tomorrow';
  static const dayStreak = 'day streak';
  static const ofThePlan = 'of the plan';
  static const restWell = 'Rest well';
  static const wellDone = 'Well done';

  // Road explore
  static const backToToday = 'Back to today';
  static const opensReading = "Opens today's reading";
  static const stopDone = 'read';
  static const stopToday = 'today';
  static const stopAhead = 'coming up';
  static String stopSemantics(int n, String state) => 'Day $n, $state';
  static const close = 'Close';
  static const sheetDone = 'Read';
  static const sheetToday = 'Today';
  static const sheetAhead = 'Coming up';
  static const sheetDateNote = 'If you read one day at a time from today.';
  static const readDay = 'Read';
  static const readAgain = 'Read again';
  static const previewDay = 'Preview the reading';
  static const whatHappened = 'WHAT HAPPENED';
  static const whyItMatters = 'WHY IT MATTERS';
  static const share = 'Share';
  static String readRef(String ref) => 'Read $ref';
  static String dateLong(DateTime d) =>
      '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

  // Streak page
  static const streakTitle = 'Your streak';
  static const daysWithTheWord = 'DAYS WITH THE WORD';
  static const legendRead = 'Read';
  static const legendGrace = 'Grace day';
  static const legendToday = 'Today';
  static const graceTitle = 'One grace day, every week';
  static const graceBody =
      'Life happens. Miss one day in a week and a grace day keeps your '
      'streak going. It shows as a leaf, never as a miss.';
  static const back = 'Back';

  // Plan picker sheet
  static const planSheetTitle = 'Reading plans';
  static const planSheetBody =
      'Your place in each plan is kept when you switch.';
  static const plansLoadError = "Plans couldn't be loaded.";
  static String startsOnLocked(String label, int days) =>
      'Starts $label · ${days == 1 ? '1 day' : '$days days'} to go';
  static const remindMe = 'Show on Today';
  static const joinCaps = 'Join';
  static const dismiss = 'Dismiss';
  static const stopCatchUp = 'catch up';
  static const sheetCatchUp = 'Catch up';
  static const readCatchUp = 'Read this day';
  static const warmUp =
      'While you wait, warm up with the New Testament in 90 days or Psalms in 30.';
  static String yearStartsIn(String title, int days) =>
      days == 1 ? '$title starts tomorrow' : '$title starts in $days days';
  static String catchUp(int today, int n) => n == 1
      ? 'Today is day $today. 1 earlier day is waiting whenever you want it.'
      : 'Today is day $today. $n earlier days are waiting whenever you want them.';
  static String yearOpenToday(String title) => '$title starts today';
  static String yearOpenNow(String title, int day) =>
      '$title is open. Join at day $day.';
  static String daysRead(int n, int total) => '$n of $total days read';
  static String resumesAt(int n, int total) => 'Resumes at $n of $total days';

  static String chapters(int n) => n == 1 ? '1 chapter' : '$n chapters';
  static String doneCaps(String passage) => 'DONE · ${passage.toUpperCase()}';
  static String dayN(int n) => 'Day $n';
  // World company: aggregate counts only. A null count means "a few".
  static String peopleReadToday(int day, String? count) => count == null
      ? 'A few people read Day $day today'
      : '$count people read Day $day today';
  static String youAndOthersFinished(int day, String? others) => others == null
      ? 'You finished Day $day with a few others'
      : 'You and $others others finished Day $day';
  static String tomorrowDay(int n) => 'Tomorrow: Day $n';
  static String dayOfTotal(int n, int total) => 'Day $n of $total';
  static String streakDays(int n) => n == 1 ? 'day' : 'days';
  static String streakChipSemantics(int n) =>
      n == 1 ? '1 day streak' : '$n day streak';
  static String longest(int n) =>
      n == 1 ? 'Longest: 1 day' : 'Longest: $n days';
  static String totalDays(int n) =>
      n == 1 ? '1 day in total' : '$n days in total';
  static String inARow(int n) => n == 1 ? '1 day in a row' : '$n days in a row';
  static String percent(int p) => '$p%';
  static String dateCaps(DateTime d) =>
      '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}'
          .toUpperCase();
  static String partCaps(DateTime d, DayPart part) =>
      '${_weekdays[d.weekday - 1]} ${part.label}'.toUpperCase();
  static String monthYear(DateTime d) => '${_months[d.month - 1]} ${d.year}';

  static const weekdayInitials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
}
