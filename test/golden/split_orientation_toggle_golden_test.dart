import 'package:alchemist/alchemist.dart';
import 'package:flutter/widgets.dart';
import 'package:openbaptisthymnal/core/widgets/split_orientation_toggle.dart';
import 'package:openbaptisthymnal/core/widgets/split_pane.dart';

// The toggle's selected state is expressed purely in colour and fill, which the
// widget test deliberately doesn't assert (too brittle in code). A golden is the
// right tool for it: it pins the appearance without hard-coding a hex value.
//
// The AnimatedContainer inside is a one-shot 160ms transition, not a loop, so it
// settles and the golden is stable.
void main() {
  Widget toggle(SplitOrientation orientation) => SizedBox(
        width: 160,
        child: SplitOrientationToggle(
          orientation: orientation,
          onChanged: (_) {},
        ),
      );

  goldenTest(
    'renders both selection states',
    fileName: 'split_orientation_toggle',
    builder: () => GoldenTestGroup(
      scenarioConstraints: const BoxConstraints(maxWidth: 160),
      children: [
        GoldenTestScenario(
          name: 'vertical selected',
          child: toggle(SplitOrientation.vertical),
        ),
        GoldenTestScenario(
          name: 'horizontal selected',
          child: toggle(SplitOrientation.horizontal),
        ),
      ],
    ),
  );
}
