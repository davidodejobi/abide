import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/notifications/notification_service.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';

/// Minutes after local midnight the daily reading reminder fires, or null
/// when it is off (the default).
final readingReminderProvider =
    NotifierProvider<ReadingReminderNotifier, int?>(ReadingReminderNotifier.new);

class ReadingReminderNotifier extends Notifier<int?> {
  static const title = "Today's reading is ready";
  static const body = 'A few quiet minutes with Scripture.';

  @override
  int? build() => ref.watch(storageServiceProvider).getReadingReminderMinutes();

  /// Turns the reminder on at [hour]:[minute], asking permission first.
  /// Returns false (and stays off) when permission is refused.
  Future<bool> enable(int hour, int minute) async {
    final service = ref.read(notificationServiceProvider);
    if (!await service.requestPermission()) return false;
    await service.scheduleDaily(
      id: NotificationIds.dailyReading,
      hour: hour,
      minute: minute,
      title: title,
      body: body,
    );
    state = hour * 60 + minute;
    await ref.read(storageServiceProvider).saveReadingReminderMinutes(state);
    return true;
  }

  Future<void> disable() async {
    await ref
        .read(notificationServiceProvider)
        .cancel(NotificationIds.dailyReading);
    state = null;
    await ref.read(storageServiceProvider).saveReadingReminderMinutes(null);
  }
}
