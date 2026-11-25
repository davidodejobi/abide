/// Short, calm date for a note row: "Today, 6:40 am", "Yesterday", a weekday for
/// the past week, then "12 Mar" (and the year once it is not this year).
String noteDateLabel(DateTime when, DateTime now, {bool use24Hour = false}) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  // UTC keys: a calendar-day difference must not shift with a DST change.
  final day = DateTime.utc(when.year, when.month, when.day);
  final today = DateTime.utc(now.year, now.month, now.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) {
    final m = when.minute.toString().padLeft(2, '0');
    if (use24Hour) return 'Today, ${when.hour.toString().padLeft(2, '0')}:$m';
    final h = when.hour % 12 == 0 ? 12 : when.hour % 12;
    return 'Today, $h:$m ${when.hour < 12 ? 'am' : 'pm'}';
  }
  if (diff == 1) return 'Yesterday';
  if (diff > 1 && diff < 7) return weekdays[when.weekday - 1];
  final base = '${when.day} ${months[when.month - 1]}';
  return when.year == now.year ? base : '$base ${when.year}';
}
