import 'package:material_ui/material_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app.dart';
import 'core/theme/lum_theme.dart';
import 'core/storage/storage_provider.dart';
import 'core/utils/services/file_storage_service.dart';
import 'core/sync/sync_providers.dart';
import 'core/widgets/splash_intro.dart';
import 'features/bible/data/sources/local/installed_bible_store.dart';
import 'features/bible/providers/bible_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LumTheme.registerFontLicenses();

  await FileStorageService.init();
  await initSupabaseIfConfigured();
  final prefs = await SharedPreferences.getInstance();

  // Downloaded Bibles are read before the first frame so a saved edition that
  // lives on disk is known to the reader from the start.
  final bibleStore = await createInstalledBibleStore();
  final installedBibles = await bibleStore.list();

  // The intro's art, built while the native splash still shows.
  await SplashIntro.preload();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        installedBibleStoreProvider.overrideWithValue(bibleStore),
        initialInstalledBiblesProvider.overrideWithValue(installedBibles),
      ],
      child: const AbideApp(),
    ),
  );
}
