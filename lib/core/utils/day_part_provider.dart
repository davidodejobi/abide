import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/utils/time_greeting.dart';
import 'package:openbaptisthymnal/features/daily/providers/daily_providers.dart';

/// The clock behind [dayPartProvider]; override in tests.
final dayPartClockProvider = Provider<DateTime Function()>((_) => DateTime.now);

/// The current part of the day from the phone's local time. Re-evaluates at
/// each boundary (5, 12, 17, 21), on app resume and when the date key moves.
final dayPartProvider =
    NotifierProvider<DayPartNotifier, DayPart>(DayPartNotifier.new);

class DayPartNotifier extends Notifier<DayPart> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  DayPart build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      _timer?.cancel();
      WidgetsBinding.instance.removeObserver(this);
    });
    ref.listen(todayKeyProvider, (_, __) => refresh());
    final now = ref.read(dayPartClockProvider)();
    _schedule(now);
    return DayPart.forHour(now.hour);
  }

  void _schedule(DateTime now) {
    _timer?.cancel();
    // A second past the boundary, so the timer never fires on the old part.
    _timer = Timer(
      DayPart.nextBoundary(now).difference(now) + const Duration(seconds: 1),
      refresh,
    );
  }

  void refresh() {
    final now = ref.read(dayPartClockProvider)();
    state = DayPart.forHour(now.hour);
    _schedule(now);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }
}
