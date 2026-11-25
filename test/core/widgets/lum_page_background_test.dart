import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/widgets/lum_page_background.dart';

void main() {
  for (final b in Brightness.values) {
    testWidgets('paints the ${b.name} page colour, both glows and the child',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(brightness: b),
        home: const LumPageBackground(child: Text('content')),
      ));

      final tokens = b == Brightness.dark ? LumColors.dark : LumColors.light;
      final boxes = tester
          .widgetList<DecoratedBox>(find.descendant(
            of: find.byType(LumPageBackground),
            matching: find.byType(DecoratedBox),
          ))
          .map((d) => d.decoration as BoxDecoration)
          .toList();

      expect(boxes.first.color, tokens.bgPage);
      final glows = boxes
          .map((d) => d.gradient)
          .whereType<RadialGradient>()
          .map((g) => g.colors.first)
          .toList();
      expect(glows, [tokens.glowPageTl, tokens.glowPageBr]);
      expect(find.text('content'), findsOneWidget);
    });
  }
}
