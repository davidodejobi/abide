import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:open_baptist_hymnal/utils/extensions/context_extensions.dart';
import 'package:open_baptist_hymnal/utils/extensions/num_extensions.dart';
import 'package:open_baptist_hymnal/utils/extensions/string_extensions.dart';

import '../../../utils/theme/theme.dart';

/// Favorites tab screen - Shows saved/favorited hymns
@RoutePage()
class FavoritesTabScreen extends ConsumerStatefulWidget {
  const FavoritesTabScreen({super.key});

  @override
  ConsumerState<FavoritesTabScreen> createState() => _FavoritesTabScreenState();
}

class _FavoritesTabScreenState extends ConsumerState<FavoritesTabScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Text(
              'Favorites',
              style: AppTextStyles.headlineLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // Empty state
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Lottie.asset(
                      'heart-pop'.lottie,
                      width: 128,
                      height: 128,
                    ),
                    Text(
                      'No favorites yet',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                8.h,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    'Tap the heart icon on any hymn to add it to your favorites',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                (context.screenSize.height * 0.2).h,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
