import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app.dart';
import 'core/theme/lum_theme.dart';
import 'core/storage/storage_provider.dart';
import 'core/utils/services/file_storage_service.dart';
import 'core/widgets/splash_intro.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LumTheme.registerFontLicenses();

  await FileStorageService.init();
  final prefs = await SharedPreferences.getInstance();

  // The intro's art, built while the native splash still shows.
  await SplashIntro.preload();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const AbideApp(),
    ),
  );
}
