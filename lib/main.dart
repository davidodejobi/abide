import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app.dart';
import 'core/storage/storage_provider.dart';
import 'core/utils/services/file_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FileStorageService.init();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const AbideApp(),
    ),
  );
}
