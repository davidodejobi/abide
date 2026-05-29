import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:toastification/toastification.dart';

import 'router/app_router.dart';
import 'theme/theme.dart';
import 'theme/theme_provider.dart';

/// Provider for the app router instance
final appRouterProvider = Provider<AppRouter>((ref) => AppRouter());

class AbideApp extends ConsumerWidget {
  const AbideApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appRouter = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return ToastificationWrapper(
      child: MaterialApp.router(
        title: 'Abide',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        routerConfig: appRouter.config(),
      ),
    );
  }
}
