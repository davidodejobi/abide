import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/bible/domain/verse_ref.dart';
import 'package:openbaptisthymnal/features/daily/domain/plan_summary.dart';
import 'package:openbaptisthymnal/features/daily/domain/reading_plan.dart';

ReadingPlan _plan(List<String> ranges) => ReadingPlan(
      id: 'p',
      title: 'P',
      description: '',
      days: [
        for (var i = 0; i < ranges.length; i++)
          PlanDay(dayIndex: i + 1, passages: [VerseRange.tryParse(ranges[i])!]),
      ],
    );

void main() {
  test('chapters in a day span the range', () {
    final plan = _plan(['JHN.1.1-3.36']);
    expect(chaptersInDay(plan.days.first), 3);
  });

  test('average chapters per day rounds and never drops below one', () {
    expect(averageChaptersPerDay(_plan(['JHN.1.1-3.36', 'JHN.4.1-5.47'])), 3);
    expect(averageChaptersPerDay(_plan(['PSA.1.1-1.6'])), 1);
    expect(averageChaptersPerDay(_plan([])), 1);
  });

  test('finish date is the last day of the plan', () {
    expect(planFinishDate(DateTime(2026, 11, 25), 1), DateTime(2026, 11, 25));
    expect(planFinishDate(DateTime(2026, 11, 25), 30), DateTime(2026, 12, 24));
    expect(planFinishDate(DateTime(2026, 12, 20), 365), DateTime(2027, 12, 19));
  });
}
