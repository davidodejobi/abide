import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/widgets/split_orientation_toggle.dart';
import 'package:openbaptisthymnal/core/widgets/split_pane.dart';

// These verify that the toggle renders both segments and notifies the parent
// when tapped. We don't assert visual selected state — too coupled to colors.
void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders both orientation segments', (tester) async {
    await tester.pumpWidget(host(SplitOrientationToggle(
      orientation: SplitOrientation.vertical,
      onChanged: (_) {},
    )));

    expect(find.byIcon(Icons.vertical_split_rounded), findsOneWidget);
    expect(find.byIcon(Icons.horizontal_split_rounded), findsOneWidget);
  });

  testWidgets('tapping horizontal segment fires the callback with horizontal',
      (tester) async {
    SplitOrientation? received;
    await tester.pumpWidget(host(SplitOrientationToggle(
      orientation: SplitOrientation.vertical,
      onChanged: (o) => received = o,
    )));

    await tester.tap(find.byIcon(Icons.horizontal_split_rounded));
    await tester.pump();

    expect(received, SplitOrientation.horizontal);
  });

  testWidgets('tapping vertical segment fires the callback with vertical',
      (tester) async {
    SplitOrientation? received;
    await tester.pumpWidget(host(SplitOrientationToggle(
      orientation: SplitOrientation.horizontal,
      onChanged: (o) => received = o,
    )));

    await tester.tap(find.byIcon(Icons.vertical_split_rounded));
    await tester.pump();

    expect(received, SplitOrientation.vertical);
  });
}
