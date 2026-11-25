import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/theme/app_theme.dart';
import 'package:openbaptisthymnal/features/daily/ui/daily_strings.dart';
import 'package:openbaptisthymnal/features/share_card/ui/share_card_style.dart';
import 'package:openbaptisthymnal/features/share_card/ui/widgets/road_card.dart';

void main() {
  Widget card(ShareCardStyle style, ShareCardFormat format,
          {int streak = 7, String? passage = 'John 3', String? landmark}) =>
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: RoadCard(
                style: style,
                format: format,
                day: 42,
                totalDays: 365,
                planTitle: 'Bible in a Year',
                streak: streak,
                passage: passage,
                landmarkTitle: landmark,
              ),
            ),
          ),
        ),
      );

  for (final style in ShareCardStyle.presets) {
    for (final format in ShareCardFormat.values) {
      testWidgets('${style.id} ${format.name} shows the card content',
          (t) async {
        await t.pumpWidget(card(style, format, landmark: 'The Garden'));
        expect(find.text('DAY 42 OF BIBLE IN A YEAR'), findsOneWidget);
        expect(find.text('John 3'), findsOneWidget);
        expect(find.text(DailyStrings.streakCount(7)), findsOneWidget);
        expect(find.text('Near The Garden'), findsOneWidget);
        expect(find.text('Lumway'), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    }
  }

  testWidgets('no streak and no passage leaves those lines out', (t) async {
    await t.pumpWidget(
        card(ShareCardStyle.presets.first, ShareCardFormat.square,
            streak: 0, passage: null));
    expect(find.textContaining('streak'), findsNothing);
    expect(find.text('John 3'), findsNothing);
    expect(find.text('Lumway'), findsOneWidget);
  });

  test('layout keeps today in view and ahead stops above it', () {
    final l = RoadLayout(const Size(300, 330), 42, 365);
    expect(l.at(42).dy, closeTo(330 * 0.66, 0.001));
    expect(l.at(43).dy, lessThan(l.at(42).dy));
    expect(l.stops.first, 39);
    expect(RoadLayout(const Size(300, 330), 1, 5).stops.toList(),
        [0, 1, 2, 3, 4, 5]);
  });

  test('share text', () {
    expect(
      DailyStrings.roadShareText(
          day: 42, plan: 'Bible in a Year', streak: 7, passage: 'John 3'),
      'Day 42 of Bible in a Year\n7 day streak\nJohn 3',
    );
  });
}
