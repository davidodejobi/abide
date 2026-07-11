import 'package:alchemist/alchemist.dart';
import 'package:flutter/widgets.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/hymn_list_tile.dart';

// Captures the states of a hymn row side by side, so a styling change shows up
// as a pixel diff rather than as a surprise in production. HymnListTile is a
// pure StatelessWidget with no animation, so the settled frame is stable.
void main() {
  Widget row({
    required String number,
    required String title,
    bool isFavorited = false,
  }) {
    return SizedBox(
      width: 340,
      child: HymnListTile(
        number: number,
        title: title,
        isFavorited: isFavorited,
        onTap: () {},
      ),
    );
  }

  goldenTest(
    'renders every hymn row state',
    fileName: 'hymn_list_tile',
    builder: () => GoldenTestGroup(
      scenarioConstraints: const BoxConstraints(maxWidth: 340),
      children: [
        GoldenTestScenario(
          name: 'default',
          child: row(number: '23', title: 'Amazing Grace'),
        ),
        GoldenTestScenario(
          name: 'favorited',
          child: row(
            number: '23',
            title: 'Amazing Grace',
            isFavorited: true,
          ),
        ),
        GoldenTestScenario(
          // The number badge pads to 3 digits; a 4-digit hymn must not reflow
          // the row or clip.
          name: 'four digit number',
          child: row(number: '1024', title: 'Blessed Assurance'),
        ),
        GoldenTestScenario(
          name: 'long title truncates',
          child: row(
            number: '7',
            title: 'Come Thou Fount of Every Blessing, Tune My Heart to Sing '
                'Thy Grace',
          ),
        ),
      ],
    ),
  );
}
