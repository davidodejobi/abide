import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                const Icon(
                  Icons.favorite_outline,
                  size: 64,
                  color: AppColors.neutral400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No favorites yet',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.neutral800,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    'Tap the heart icon on any hymn to add it to your favorites',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
