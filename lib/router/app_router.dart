import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../presentation/pages/dashboard_screen.dart';
import '../presentation/pages/hymn_detail_page.dart';
import '../presentation/pages/tabs/favorites_tab_screen.dart';
import '../presentation/pages/tabs/home_tab_screen.dart';
import '../presentation/pages/tabs/settings_tab_screen.dart';

part 'app_router.gr.dart';

/// The main application router that handles all navigation
@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        // Dashboard is the root with tabs
        AutoRoute(
          page: DashboardRoute.page,
          initial: true,
          children: [
            AutoRoute(page: HomeTabRoute.page),
            AutoRoute(page: FavoritesTabRoute.page),
            AutoRoute(page: SettingsTabRoute.page),
          ],
        ),
        // Standalone routes (pushed on top of dashboard)
        AutoRoute(page: HymnDetailRoute.page),
      ];

  @override
  RouteType get defaultRouteType => const RouteType.adaptive();
}
