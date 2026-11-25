import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/utils/day_part_provider.dart';
import 'package:openbaptisthymnal/core/utils/time_greeting.dart';

void main() {
  test('Given an hour, Then the part follows the 5/12/17/21 boundaries', () {
    const cases = {
      0: DayPart.night,
      4: DayPart.night,
      5: DayPart.morning,
      11: DayPart.morning,
      12: DayPart.afternoon,
      16: DayPart.afternoon,
      17: DayPart.evening,
      20: DayPart.evening,
      21: DayPart.night,
    };
    cases.forEach((h, p) => expect(DayPart.forHour(h), p, reason: '$h:00'));
    expect(TimeGreeting.forHour(23).greeting, 'Good night');
    expect(TimeGreeting.forHour(3).greeting, 'Good night');
    expect(TimeGreeting.forHour(18).greeting, 'Good evening');
  });

  test('Given a time, Then the next boundary is the next 5/12/17/21', () {
    expect(DayPart.nextBoundary(DateTime(2026, 1, 1, 4, 59)),
        DateTime(2026, 1, 1, 5));
    expect(DayPart.nextBoundary(DateTime(2026, 1, 1, 12)),
        DateTime(2026, 1, 1, 17));
    expect(DayPart.nextBoundary(DateTime(2026, 1, 1, 22)),
        DateTime(2026, 1, 2, 5));
  });

  testWidgets('Given the clock crosses a boundary, Then the provider re-emits',
      (t) async {
    var now = DateTime(2026, 1, 1, 11, 59, 30);
    final c = ProviderContainer(
        overrides: [dayPartClockProvider.overrideWithValue(() => now)]);
    final seen = <DayPart>[];
    c.listen(dayPartProvider, (_, n) => seen.add(n), fireImmediately: true);
    expect(seen, [DayPart.morning]);

    now = DateTime(2026, 1, 1, 12, 0, 31);
    await t.pump(const Duration(seconds: 32));
    expect(seen, [DayPart.morning, DayPart.afternoon]);
    c.dispose(); // cancels the timers before the test ends
  });
}
