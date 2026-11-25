// Time-of-day greeting logic shared between the home header and the onboarding
// scene screen, so both speak with one voice and draw the same celestial body.

/// The four parts of the day the app reacts to.
enum DayPart {
  morning,
  afternoon,
  evening,
  night;

  /// Morning 5-12, afternoon 12-17, evening 17-21, night 21-5.
  static DayPart forHour(int hour) {
    if (hour >= 5 && hour < 12) return morning;
    if (hour >= 12 && hour < 17) return afternoon;
    if (hour >= 17 && hour < 21) return evening;
    return night;
  }

  /// The hours at which the part changes, ascending.
  static const boundaries = [5, 12, 17, 21];

  /// The next part boundary strictly after [now].
  static DateTime nextBoundary(DateTime now) {
    for (final h in boundaries) {
      final b = DateTime(now.year, now.month, now.day, h);
      if (b.isAfter(now)) return b;
    }
    return DateTime(now.year, now.month, now.day + 1, boundaries.first);
  }

  /// Lower-case name, e.g. "evening".
  String get label => name;
}

/// A small bundle describing how to greet the user for a given hour.
class TimeGreeting {
  const TimeGreeting({
    required this.part,
    required this.greeting,
    required this.accent,
  });

  /// Which part of the day this falls in.
  final DayPart part;

  /// Short, clean salutation — e.g. "Good evening". The caller appends the
  /// user's name where appropriate.
  final String greeting;

  /// A short hand-written accent line echoing onboarding's quiet voice.
  final String accent;

  /// Whether to draw the moon (night) rather than the sun (day).
  bool get isNight => part == DayPart.evening || part == DayPart.night;

  /// Resolve the greeting for a 24-hour [hour] (0–23).
  factory TimeGreeting.forHour(int hour) =>
      TimeGreeting.forPart(DayPart.forHour(hour));

  /// Resolve the greeting for a [DayPart].
  factory TimeGreeting.forPart(DayPart part) {
    if (part == DayPart.morning) {
      return const TimeGreeting(
        part: DayPart.morning,
        greeting: 'Good morning',
        accent: 'his mercies are new with the light.',
      );
    }
    if (part == DayPart.afternoon) {
      return const TimeGreeting(
        part: DayPart.afternoon,
        greeting: 'Good afternoon',
        accent: 'step aside for just a moment.',
      );
    }
    if (part == DayPart.evening) {
      return const TimeGreeting(
        part: DayPart.evening,
        greeting: 'Good evening',
        accent: 'lay down what was heavy to carry.',
      );
    }
    return const TimeGreeting(
      part: DayPart.night,
      greeting: 'Good night',
      accent: 'he gives his beloved sleep.',
    );
  }

  /// Convenience: resolve for [now] (defaults to the current time).
  factory TimeGreeting.now([DateTime? now]) =>
      TimeGreeting.forHour((now ?? DateTime.now()).hour);
}
