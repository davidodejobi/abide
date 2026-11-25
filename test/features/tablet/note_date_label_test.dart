import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/tablet/domain/note_date_label.dart';

void main() {
  final now = DateTime(2026, 11, 25, 15, 0); // a Wednesday

  test('today shows a 12 hour time', () {
    expect(noteDateLabel(DateTime(2026, 11, 25, 6, 40), now), 'Today, 6:40 am');
    expect(noteDateLabel(DateTime(2026, 11, 25, 0, 5), now), 'Today, 12:05 am');
    expect(noteDateLabel(DateTime(2026, 11, 25, 13, 0), now), 'Today, 1:00 pm');
  });

  test('yesterday, weekday, then date', () {
    expect(noteDateLabel(DateTime(2026, 11, 24, 23, 59), now), 'Yesterday');
    expect(noteDateLabel(DateTime(2026, 11, 22), now), 'Sunday');
    expect(noteDateLabel(DateTime(2026, 11, 18), now), '18 Nov');
    expect(noteDateLabel(DateTime(2025, 3, 2), now), '2 Mar 2025');
  });

  test('24 hour clock when asked', () {
    expect(noteDateLabel(DateTime(2026, 11, 25, 13, 5), now, use24Hour: true),
        'Today, 13:05');
  });

  test('day difference is calendar based across a DST change', () {
    // 25 hours between these instants in a DST-short day must still be 1 day.
    final spring = DateTime(2026, 3, 29, 12);
    expect(noteDateLabel(DateTime(2026, 3, 28, 23), spring), 'Yesterday');
    final autumn = DateTime(2026, 10, 26, 0, 30);
    expect(noteDateLabel(DateTime(2026, 10, 25, 23, 30), autumn), 'Yesterday');
  });
}
