import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/core/utils/extensions/context_extensions.dart';
import 'package:openbaptisthymnal/core/utils/extensions/num_extensions.dart';
import 'package:openbaptisthymnal/core/utils/extensions/string_extensions.dart';
import 'package:openbaptisthymnal/core/utils/extensions/widget_extensions.dart';
import 'package:openbaptisthymnal/features/hymn/providers/favorites_provider.dart';
import 'package:openbaptisthymnal/features/hymn/providers/hymnal_provider.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/hymn_list_tile.dart';

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
    final favoritesAsync = ref.watch(favoriteHymnsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          'Favorites',
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          favoritesAsync.when(
            data: (favorites) {
              if (favorites.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final favorite = favorites[index];
                      final hymn = favorite.hymn;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: HymnListTile(
                          number: hymn.number.toString(),
                          title: hymn.title,
                          isFavorited: true,
                          onTap: () {
                            // Open the hymn in the language it was favorited in
                            // so the reader matches the saved translation.
                            ref.read(languageProvider.notifier).state =
                                favorite.language;
                            final hymnId = hymn.id ??
                                'hymn_${hymn.number.toString().padLeft(4, '0')}';
                            context.router
                                .push(HymnDetailRoute(hymnId: hymnId));
                          },
                        ),
                      );
                    },
                    childCount: favorites.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ).padOnly(top: 8),
    );
  }
}
