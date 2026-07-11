import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/widgets/split_orientation_toggle.dart';
import 'package:openbaptisthymnal/core/widgets/split_pane.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// Verifies the toggle renders both segments and notifies the parent when
// tapped. We don't assert the visual selected state — too coupled to colours;
// the golden test covers appearance instead.
void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('Given a split orientation toggle', () {
    group('When it is rendered', () {
      testWidgets('Then both orientation segments are shown', (tester) async {
        await tester.pumpWidget(host(SplitOrientationToggle(
          orientation: SplitOrientation.vertical,
          onChanged: (_) {},
        )));

        expect(find.byIcon(PhosphorIcons.columns()), findsOneWidget);
        expect(find.byIcon(PhosphorIcons.rows()), findsOneWidget);
      });
    });

    group('When the horizontal segment is tapped', () {
      testWidgets('Then it reports the horizontal orientation', (tester) async {
        SplitOrientation? received;
        await tester.pumpWidget(host(SplitOrientationToggle(
          orientation: SplitOrientation.vertical,
          onChanged: (o) => received = o,
        )));

        await tester.tap(find.byIcon(PhosphorIcons.rows()));
        await tester.pump();

        expect(received, SplitOrientation.horizontal);
      });
    });

    group('When the vertical segment is tapped', () {
      testWidgets('Then it reports the vertical orientation', (tester) async {
        SplitOrientation? received;
        await tester.pumpWidget(host(SplitOrientationToggle(
          orientation: SplitOrientation.horizontal,
          onChanged: (o) => received = o,
        )));

        await tester.tap(find.byIcon(PhosphorIcons.columns()));
        await tester.pump();

        expect(received, SplitOrientation.vertical);
      });
    });
  });
}
