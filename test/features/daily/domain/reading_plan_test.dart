import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/daily/domain/reading_plan.dart';

void main() {
  ReadingPlan planOf(int dayCount) => ReadingPlan.fromJson({
        'id': 'test-plan',
        'title': 'Test Plan',
        'description': 'A plan, for testing.',
        'days': [
          for (var i = 1; i <= dayCount; i++)
            {
              'day': i,
              'passages': ['GEN.$i.1-10'],
            },
        ],
      });

  group('Given a plan and a day number', () {
    group('When the day is looked up', () {
      test('Then day 1 is the first day, because dayIndex is 1-based', () {
        // The off-by-one that would not crash: dayAt(1) returning day 2 just
        // quietly opens the wrong reading, every day, forever.
        final plan = planOf(5);

        expect(plan.dayAt(1)!.dayIndex, 1);
        expect(plan.dayAt(1)!.passages.single.toString(), 'GEN.1.1-10');
      });

      test('Then the last day is reachable', () {
        final plan = planOf(5);

        expect(plan.dayAt(5)!.dayIndex, 5);
        expect(plan.dayCount, 5);
      });

      test('Then day 0 is null, not the last element', () {
        // A negative index into a Dart list throws; a 0 that silently became
        // days[-1] would be worse. Neither happens.
        expect(planOf(5).dayAt(0), isNull);
      });

      test('Then a day past the end is null', () {
        // Reached the moment someone finishes a plan and opens the app again.
        // The caller decides what to show; it must not throw here.
        expect(planOf(5).dayAt(6), isNull);
        expect(planOf(5).dayAt(999), isNull);
      });
    });
  });

  group('Given a plan is serialized', () {
    group('When it round-trips through JSON', () {
      test('Then it survives unchanged', () {
        final original = planOf(3);

        final restored = ReadingPlan.fromJson(original.toJson());

        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.description, original.description);
        expect(restored.dayCount, 3);
        expect(
          restored.days.map((d) => d.passages.map((p) => p.toString())),
          original.days.map((d) => d.passages.map((p) => p.toString())),
        );
      });
    });
  });

  group('Given a plan with an unparseable passage', () {
    group('When it is deserialized', () {
      test('Then it throws, naming the day', () {
        // A silently-dropped passage is a day the user never reads and never
        // knows they missed. Fail loudly at load instead.
        expect(
          () => ReadingPlan.fromJson({
            'id': 'broken',
            'title': 'Broken',
            'description': '',
            'days': [
              {
                'day': 1,
                'passages': ['NOPE.1.1-10'],
              },
            ],
          }),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              allOf(contains('day 1'), contains('NOPE.1.1-10')),
            ),
          ),
        );
      });
    });
  });
}
