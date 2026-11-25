import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/providers/bottom_nav_provider.dart';
import 'package:openbaptisthymnal/features/dashboard/ui/widgets/bottom_nav_bar/bottom_nav_bar.dart';

import '../../support/pump_app.dart';

void main() {
  test('tab order is Today, Bible, Songs, Notes, You', () {
    expect(BottomNavTab.values.map((t) => t.label),
        ['Today', 'Bible', 'Songs', 'Notes', 'You']);
    expect(BottomNavTab.fromIndex(1), BottomNavTab.bible);
    expect(BottomNavTab.fromIndex(3), BottomNavTab.notes);
  });

  testWidgets('tapping each label selects the matching tab', (tester) async {
    int? tapped;
    await tester.pumpApp(GlassTabBar(
      labels: [for (final t in BottomNavTab.values) t.label],
      selectedIndex: 0,
      onTabSelected: (i) => tapped = i,
    ));
    for (final t in BottomNavTab.values) {
      await tester.tap(find.text(t.label));
      expect(BottomNavTab.fromIndex(tapped!), t);
    }
    await tester.flushTimers();
  });
}
