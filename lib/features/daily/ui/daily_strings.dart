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

  static String chapters(int n) => n == 1 ? '1 chapter' : '$n chapters';
  static String doneCaps(String passage) => 'DONE · ${passage.toUpperCase()}';
  static String dayN(int n) => 'Day $n';
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
  static String eveningCaps(DateTime d) =>
      '${_weekdays[d.weekday - 1]} evening'.toUpperCase();
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
