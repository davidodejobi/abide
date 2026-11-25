import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/features/daily/ui/daily_strings.dart';
import 'package:openbaptisthymnal/features/share_card/ui/share_card_composer.dart';
import 'package:openbaptisthymnal/features/share_card/ui/widgets/road_card.dart';

/// Composer screen for sharing the reader's road as an image: from Today, or
/// from a landmark they have reached.
@RoutePage()
class RoadShareCardPage extends StatelessWidget {
  const RoadShareCardPage({
    super.key,
    required this.day,
    required this.totalDays,
    required this.planTitle,
    this.streak = 0,
    this.passage,
    this.landmarkTitle,
    this.landmarkArt,
  });

  final int day;
  final int totalDays;
  final String planTitle;
  final int streak;
  final String? passage;
  final String? landmarkTitle;
  final String? landmarkArt;

  @override
  Widget build(BuildContext context) {
    return ShareCardComposer(
      title: DailyStrings.shareRoadTitle,
      filename: 'lumway_road_day_$day',
      cardBuilder: (style, format, showReference) => RoadCard(
        style: style,
        format: format,
        day: day,
        totalDays: totalDays,
        planTitle: planTitle,
        streak: streak,
        passage: showReference ? passage : null,
        landmarkTitle: landmarkTitle,
        landmarkArt: landmarkArt,
      ),
      textBuilder: (showReference) => DailyStrings.roadShareText(
        day: day,
        plan: planTitle,
        streak: streak,
        passage: showReference ? passage : null,
        landmark: landmarkTitle,
      ),
    );
  }
}
