import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app.dart';
import 'core/notifications/notification_service.dart';
import 'core/theme/lum_theme.dart';
import 'core/storage/storage_provider.dart';
import 'core/utils/services/file_storage_service.dart';
import 'core/widgets/splash_intro.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LumTheme.registerFontLicenses();

  await FileStorageService.init();
  final prefs = await SharedPreferences.getInstance();

  // Never let notification setup block launch: on failure the no-op default
  // stays in place.
  NotificationService? notifications;
  if (!kIsWeb) {
    try {
      final service = LocalNotificationService();
      await service.init();
      notifications = service;
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }
  }

  // The intro's art, built while the native splash still shows.
  await SplashIntro.preload();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        if (notifications != null)
          notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const AbideApp(),
    ),
  );
}
