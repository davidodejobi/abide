/// Short, calm date for a note row: "Today, 6:40", "Yesterday", a weekday for
/// the past week, then "12 Mar" (and the year once it is not this year).
String noteDateLabel(DateTime when, DateTime now) {
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
  final day = DateTime(when.year, when.month, when.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) {
    final h = when.hour % 12 == 0 ? 12 : when.hour % 12;
    final m = when.minute.toString().padLeft(2, '0');
    return 'Today, $h:$m';
  }
  if (diff == 1) return 'Yesterday';
  if (diff > 1 && diff < 7) return weekdays[when.weekday - 1];
  final base = '${when.day} ${months[when.month - 1]}';
  return when.year == now.year ? base : '$base ${when.year}';
}
