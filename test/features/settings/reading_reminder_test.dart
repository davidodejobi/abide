import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/notifications/notification_service.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/core/utils/day_part_provider.dart';
import 'package:openbaptisthymnal/features/daily/domain/reading_plan.dart';
import 'package:openbaptisthymnal/features/daily/providers/daily_providers.dart';
import 'package:openbaptisthymnal/features/settings/providers/reading_reminder_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeNotifications implements NotificationService {
  FakeNotifications({this.granted = true});
  bool granted;
  int permissionAsks = 0;
  final daily = <(int, int, int)>[];
  final once = <(int, DateTime, String)>[];
  final cancelled = <int>[];

  @override
  Future<bool> requestPermission() async {
    permissionAsks++;
    return granted;
  }

  @override
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async =>
      daily.add((id, hour, minute));

  @override
  Future<void> scheduleOnce({
    required int id,
    required DateTime at,
    required String title,
    required String body,
  }) async =>
      once.add((id, at, title));

  @override
  Future<void> cancel(int id) async => cancelled.add(id);

  @override
  Stream<void> get taps => const Stream.empty();
}

const _plan = ReadingPlan(
  id: 'bible-in-a-year',
  title: 'Bible in a Year',
  description: '',
  days: [],
  startsOn: '01-01',
  firstRunYear: 2027,
);

Future<ProviderContainer> _container(FakeNotifications fake,
    {DateTime? now}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    notificationServiceProvider.overrideWithValue(fake),
    availablePlansProvider.overrideWith((ref) async => [_plan]),
    dayPartClockProvider.overrideWithValue(() => now ?? DateTime(2026, 11, 25)),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('daily reading reminder', () {
    test('is off by default and asks nothing', () async {
      final fake = FakeNotifications();
      final c = await _container(fake);
      expect(c.read(readingReminderProvider), isNull);
      expect(fake.permissionAsks, 0);
    });

    test('enable asks permission, schedules, and persists', () async {
      final fake = FakeNotifications();
      final c = await _container(fake);
      expect(await c.read(readingReminderProvider.notifier).enable(7, 30),
          isTrue);
      expect(fake.permissionAsks, 1);
      expect(fake.daily, [(NotificationIds.dailyReading, 7, 30)]);
      expect(c.read(readingReminderProvider), 450);
      expect(c.read(storageServiceProvider).getReadingReminderMinutes(), 450);
    });

    test('denied permission schedules nothing and stays off', () async {
      final fake = FakeNotifications(granted: false);
      final c = await _container(fake);
      expect(await c.read(readingReminderProvider.notifier).enable(8, 0),
          isFalse);
      expect(fake.daily, isEmpty);
      expect(c.read(readingReminderProvider), isNull);
    });

    test('disable cancels and clears', () async {
      final fake = FakeNotifications();
      final c = await _container(fake);
      final n = c.read(readingReminderProvider.notifier);
      await n.enable(8, 0);
      await n.disable();
      expect(fake.cancelled, [NotificationIds.dailyReading]);
      expect(c.read(readingReminderProvider), isNull);
      expect(c.read(storageServiceProvider).getReadingReminderMinutes(), isNull);
    });
  });

  group('plan start reminder', () {
    test('schedules 1 Jan 2027 08:00 when turned on', () async {
      final fake = FakeNotifications();
      final c = await _container(fake);
      c.read(planRemindersProvider.notifier).toggle('bible-in-a-year', true);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(fake.permissionAsks, 1);
      expect(fake.once.single.$1, NotificationIds.forPlan('bible-in-a-year'));
      expect(fake.once.single.$2, DateTime(2027, 1, 1, 8));
      expect(fake.once.single.$3, 'Bible in a Year starts today');
    });

    test('turning it off cancels', () async {
      final fake = FakeNotifications();
      final c = await _container(fake);
      c.read(planRemindersProvider.notifier).toggle('bible-in-a-year', false);
      await Future<void>.delayed(Duration.zero);
      expect(fake.cancelled, [NotificationIds.forPlan('bible-in-a-year')]);
      expect(fake.permissionAsks, 0);
    });

    test('does not schedule once the start has passed', () async {
      final fake = FakeNotifications();
      final c = await _container(fake, now: DateTime(2027, 1, 1, 9));
      c.read(planRemindersProvider.notifier).toggle('bible-in-a-year', true);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(fake.once, isEmpty);
      expect(fake.permissionAsks, 0);
    });
  });
}
