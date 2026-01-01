import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:toastification/toastification.dart';

import 'providers/theme_provider.dart';
import 'router/app_router.dart';
import 'utils/theme/theme.dart';

/// Provider for the app router instance
final appRouterProvider = Provider<AppRouter>((ref) => AppRouter());

class OpenBaptistHymnal extends ConsumerWidget {
  const OpenBaptistHymnal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appRouter = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return ToastificationWrapper(
      child: MaterialApp.router(
        title: 'Open Baptist Hymnal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        routerConfig: appRouter.config(),
      ),
    );
  }
}
