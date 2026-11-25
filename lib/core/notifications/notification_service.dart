import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// The small surface the app needs from local notifications. The plugin sits
/// behind this so scheduling logic can be tested with a fake.
abstract class NotificationService {
  /// Asks the OS for permission. Call only when the user turns a reminder on.
  Future<bool> requestPermission();

  /// Whether permission is already granted. Never prompts.
  Future<bool> hasPermission();

  /// Repeats every day at [hour]:[minute] local time.
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  });

  /// Fires once at [at] (device local time).
  Future<void> scheduleOnce({
    required int id,
    required DateTime at,
    required String title,
    required String body,
  });

  Future<void> cancel(int id);

  /// Emits when the user taps a notification while the app is running.
  Stream<void> get taps;
}

/// First time a daily reminder at [hour]:[minute] should fire: today if that
/// is still ahead of [now], otherwise tomorrow. Pure; wall-clock fields only.
DateTime nextDailyFire(DateTime now, int hour, int minute) {
  final today = DateTime(now.year, now.month, now.day, hour, minute);
  return today.isAfter(now)
      ? today
      : DateTime(now.year, now.month, now.day + 1, hour, minute);
}

/// Does nothing. The default, and what web gets, so a failed init never
/// blocks launch and callers need no null checks.
class NoopNotificationService implements NotificationService {
  const NoopNotificationService();
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<bool> hasPermission() async => false;
  @override
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {}
  @override
  Future<void> scheduleOnce({
    required int id,
    required DateTime at,
    required String title,
    required String body,
  }) async {}
  @override
  Future<void> cancel(int id) async {}
  @override
  Stream<void> get taps => const Stream.empty();
}

/// Ids are fixed so a reschedule replaces the old one.
abstract final class NotificationIds {
  static const dailyReading = 1;

  /// Stable per plan across launches (String.hashCode is not guaranteed to be).
  static int forPlan(String planId) {
    var h = 7;
    for (final c in planId.codeUnits) {
      h = (h * 31 + c) & 0x3fffffff;
    }
    return 1000 + h % 1000000;
  }
}

class LocalNotificationService implements NotificationService {
  LocalNotificationService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<void>.broadcast();

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reading',
      'Reading reminders',
      channelDescription: 'Daily reading and plan start reminders',
    ),
    iOS: DarwinNotificationDetails(),
  );

  @override
  Stream<void> get taps => _taps.stream;

  /// Does not prompt: permission is requested later, on demand.
  Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (e) {
      debugPrint('Timezone lookup failed, reminders will use UTC: $e');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_lumway'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (_) => _taps.add(null),
    );
  }

  @override
  Future<bool> hasPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.areNotificationsEnabled() ?? false;
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    return (await ios?.checkPermissions())?.isEnabled ?? false;
  }

  @override
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  @override
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) {
    final f = nextDailyFire(tz.TZDateTime.now(tz.local), hour, minute);
    final first = tz.TZDateTime(tz.local, f.year, f.month, f.day, f.hour, f.minute);
    return _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: first,
      notificationDetails: _details,
      // ponytail: inexact avoids the exact-alarm permission; a few minutes of
      // drift is fine for a reading nudge.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> scheduleOnce({
    required int id,
    required DateTime at,
    required String title,
    required String body,
  }) {
    return _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime(
          tz.local, at.year, at.month, at.day, at.hour, at.minute),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);
}

/// A no-op until `main` overrides it with an initialised
/// [LocalNotificationService].
final notificationServiceProvider =
    Provider<NotificationService>((ref) => const NoopNotificationService());
