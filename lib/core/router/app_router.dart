import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/features/bible/ui/bible_credits_page.dart';
import 'package:openbaptisthymnal/features/bible/ui/bible_reader_page.dart';
import 'package:openbaptisthymnal/features/bible/ui/bible_tab_screen.dart';
import 'package:openbaptisthymnal/features/daily/ui/plan_days_page.dart';
import 'package:openbaptisthymnal/features/daily/ui/streak_page.dart';
import 'package:openbaptisthymnal/features/daily/ui/today_tab_screen.dart';
import 'package:openbaptisthymnal/features/dashboard/ui/dashboard_screen.dart';
import 'package:openbaptisthymnal/features/hymn/ui/favorites_tab_screen.dart';
import 'package:openbaptisthymnal/features/hymn/ui/home_tab_screen.dart';
import 'package:openbaptisthymnal/features/hymn/ui/hymn_detail_page.dart';
import 'package:openbaptisthymnal/features/tablet/ui/tablets_tab_screen.dart';
import 'package:openbaptisthymnal/features/tablet/ui/pages/tablet_editor_page.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/onboarding_page.dart';
import 'package:openbaptisthymnal/features/settings/ui/settings_tab_screen.dart';
import 'package:openbaptisthymnal/features/share_card/ui/scripture_share_card_page.dart';
import 'package:openbaptisthymnal/features/share_card/ui/share_card_page.dart';

part 'app_router.gr.dart';

/// The main application router that handles all navigation
@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  AppRouter({this.showOnboarding = false});

  /// When true, the app opens on the onboarding flow instead of the dashboard.
  final bool showOnboarding;

  @override
  List<AutoRoute> get routes => [
        // Dashboard is the root with tabs
        AutoRoute(
          page: DashboardRoute.page,
          initial: true,
          children: [
            AutoRoute(page: TodayTabRoute.page),
            AutoRoute(page: TabletsTabRoute.page),
            AutoRoute(page: HomeTabRoute.page),
            AutoRoute(page: BibleTabRoute.page),
            AutoRoute(page: SettingsTabRoute.page),
          ],
        ),
        // Standalone routes (pushed on top of dashboard)
        AutoRoute(page: BibleReaderRoute.page),
        AutoRoute(page: StreakRoute.page),
        AutoRoute(page: PlanDaysRoute.page),
        AutoRoute(page: FavoritesTabRoute.page),
        AutoRoute(page: TabletEditorRoute.page),
        AutoRoute(page: HymnDetailRoute.page),
        AutoRoute(page: ShareCardRoute.page),
        AutoRoute(page: ScriptureShareCardRoute.page),
        AutoRoute(page: BibleCreditsRoute.page),
        AutoRoute(page: OnboardingRoute.page),
      ];

  /// Routes the app to onboarding on first launch, otherwise the dashboard.
  DeepLinkBuilder get onboardingDeepLink => (deepLink) {
        if (showOnboarding) {
          return DeepLink.single(const OnboardingRoute());
        }
        return DeepLink.defaultPath;
      };

  @override
  RouteType get defaultRouteType => const RouteType.adaptive();
}
