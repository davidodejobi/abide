import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/widgets/lum_button.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('exposes a tap action and fires it', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpApp(
        LumButton(label: 'Go', onPressed: () => taps++));
    final node = tester.getSemantics(find.byType(LumButton));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    tester.semantics.tap(find.semantics.byLabel('Go'));
    expect(taps, 1);
    handle.dispose();
  });

  testWidgets('disabled has no tap action', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpApp(const LumButton(label: 'Go', onPressed: null));
    expect(
        tester
            .getSemantics(find.byType(LumButton))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isFalse);
    handle.dispose();
  });

  testWidgets('no overflow at 2x text on a narrow width', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 318,
            child: LumButton(
                label: 'Open the App Store',
                icon: const Icon(Icons.apple),
                onPressed: () {}),
          ),
        ),
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
