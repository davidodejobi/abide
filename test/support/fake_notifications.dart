import 'package:openbaptisthymnal/core/notifications/notification_service.dart';

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
  Future<bool> hasPermission() async => granted;

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
