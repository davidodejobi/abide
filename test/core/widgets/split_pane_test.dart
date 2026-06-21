import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/widgets/split_pane.dart';

// SplitPane only owns layout — these verify that the right top-level widget
// (Row vs Column) is mounted for each orientation and that both panes are
// reachable in the tree.
void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('vertical orientation lays out children in a Row', (tester) async {
    await tester.pumpWidget(host(const SplitPane(
      orientation: SplitOrientation.vertical,
      primary: Text('left'),
      secondary: Text('right'),
    )));

    await tester.pumpAndSettle();

    expect(find.text('left'), findsOneWidget);
    expect(find.text('right'), findsOneWidget);
    expect(find.byKey(const ValueKey('split-vertical')), findsOneWidget);
    expect(find.byKey(const ValueKey('split-horizontal')), findsNothing);
  });

  testWidgets('horizontal orientation lays out children in a Column',
      (tester) async {
    await tester.pumpWidget(host(const SplitPane(
      orientation: SplitOrientation.horizontal,
      primary: Text('top'),
      secondary: Text('bottom'),
    )));

    await tester.pumpAndSettle();

    expect(find.text('top'), findsOneWidget);
    expect(find.text('bottom'), findsOneWidget);
    expect(find.byKey(const ValueKey('split-horizontal')), findsOneWidget);
    expect(find.byKey(const ValueKey('split-vertical')), findsNothing);
  });

  testWidgets('flipping orientation swaps the inner layout', (tester) async {
    var orientation = SplitOrientation.vertical;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Column(
              children: [
                ElevatedButton(
                  onPressed: () => setState(() {
                    orientation = orientation == SplitOrientation.vertical
                        ? SplitOrientation.horizontal
                        : SplitOrientation.vertical;
                  }),
                  child: const Text('flip'),
                ),
                Expanded(
                  child: SplitPane(
                    orientation: orientation,
                    primary: const Text('A'),
                    secondary: const Text('B'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('split-vertical')), findsOneWidget);

    await tester.tap(find.text('flip'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('split-horizontal')), findsOneWidget);
    expect(find.byKey(const ValueKey('split-vertical')), findsNothing);
  });
}
