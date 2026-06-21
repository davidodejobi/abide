import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/features/onboarding/domain/seed_welcome_note.dart';
import 'package:openbaptisthymnal/features/tablet/providers/tablets_providers.dart';
import 'package:toastification/toastification.dart';

import 'router/app_router.dart';
import 'storage/storage_provider.dart';
import 'theme/theme.dart';
import 'theme/theme_provider.dart';

/// Provider for the app router instance. In debug builds the onboarding flow
/// shows on every launch so it can be reviewed; release builds show it once.
final appRouterProvider = Provider<AppRouter>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final showOnboarding = !storage.isOnboardingComplete();
  return AppRouter(showOnboarding: showOnboarding);
});

class AbideApp extends HookConsumerWidget {
  const AbideApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appRouter = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    // One-shot: drop the example "Welcome to your notes" note in the notes
    // tab the first time this build of the app starts up. Idempotent — a
    // shared-prefs flag guarantees we never re-create it on later launches.
    useEffect(() {
      final storage = ref.read(storageServiceProvider);
      final repo = ref.read(tabletsRepositoryProvider);
      seedWelcomeNoteIfNeeded(
        storage: storage,
        createNote: repo.createNote,
        userName: storage.getUserName(),
      );
      return null;
    }, const []);

    return ToastificationWrapper(
      child: MaterialApp.router(
        title: 'Abide',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        routerConfig: appRouter.config(
          deepLinkBuilder: appRouter.onboardingDeepLink,
        ),
      ),
    );
  }
}
