import 'dart:convert';

/// The calendar day plan day [day] falls on if the reader keeps to one day at
/// a time from [today], where [currentDay] is the day to read today. Calendar
/// arithmetic (not a 24 h Duration), so it is right across DST and month ends.
DateTime dateForDay({
  required int day,
  required int currentDay,
  required DateTime today,
}) =>
    DateTime(today.year, today.month, today.day + (day - currentDay));

/// Keeps the explore camera on the road: from the start (0) to the plan's last
/// day. [look] is a fractional stop position.
double clampLook(double look, int totalDays) =>
    look.clamp(0.0, totalDays.toDouble());

/// What the road tells about a landmark when it is tapped: a short retelling
/// in our own words and why it matters. Never quoted Scripture.
class LandmarkStory {
  const LandmarkStory({required this.story, required this.why});

  final String story;
  final String why;
}

/// Parses `landmark_stories.json`: `{ "<landmark id>": {"story": "", "why": ""} }`.
Map<String, LandmarkStory> parseLandmarkStories(String json) => {
      for (final e in (jsonDecode(json) as Map<String, dynamic>).entries)
        e.key: LandmarkStory(
          story: (e.value as Map<String, dynamic>)['story'] as String,
          why: (e.value as Map<String, dynamic>)['why'] as String,
        ),
    };
