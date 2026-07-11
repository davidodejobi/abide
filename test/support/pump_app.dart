import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/theme/app_theme.dart';

/// Shared harness for widget tests.
///
/// The caller is responsible for its own `ProviderScope(overrides: ...)` — this
/// only supplies the app chrome (theme + MaterialApp + Scaffold) that widgets
/// need in order to find a Directionality, Material and MediaQuery ancestor.
extension PumpApp on WidgetTester {
  /// Pumps [scoped] inside the app's real theme.
  ///
  /// Deliberately a fixed pump, never `pumpAndSettle`: several screens hold
  /// looping animations (the nav bar's AnimatedSlide, shimmer, Lottie) and
  /// `pumpAndSettle` waits for a quiet frame that never arrives.
  Future<void> pumpApp(Widget scoped, {ThemeData? theme}) async {
    await pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme ?? AppTheme.darkTheme,
        home: Scaffold(body: scoped),
      ),
    );
    await pump(const Duration(seconds: 1));
  }

  /// Tears the tree down and lets stragglers fire inside the test body.
  ///
  /// Call at the END of any test whose tree holds a stream subscription or a
  /// repeating animation. Otherwise the timer outlives the test and trips the
  /// framework's pending-timer assertion, failing a test that actually passed.
  Future<void> flushTimers() async {
    await pumpWidget(const SizedBox());
    await pump(const Duration(milliseconds: 500));
  }
}

/// An in-memory Drift database.
///
/// Override [appDatabaseProvider] with this and the entire provider graph
/// (DAOs, repositories, notifiers) runs against it, so seeding a test is just a
/// DAO call. Close it in `tearDown`.
AppDatabase testDb() => AppDatabase.forTesting(NativeDatabase.memory());
