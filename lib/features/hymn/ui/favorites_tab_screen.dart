import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/utils/extensions/string_extensions.dart';
import 'package:openbaptisthymnal/core/widgets/lum_circle_button.dart';
import 'package:openbaptisthymnal/core/widgets/lum_group_card.dart';
import 'package:openbaptisthymnal/core/widgets/lum_page_background.dart';
import 'package:openbaptisthymnal/features/hymn/providers/favorites_provider.dart';
import 'package:openbaptisthymnal/features/hymn/providers/hymnal_provider.dart';
import 'package:openbaptisthymnal/features/hymn/ui/hymn_strings.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/hymn_list_tile.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Favourites: the hymns the reader hearted, each in the language it was saved
/// in.
@RoutePage()
class FavoritesTabScreen extends ConsumerWidget {
  const FavoritesTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lum;
    final favoritesAsync = ref.watch(favoriteHymnsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LumPageBackground(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(LumSize.screenGutter,
                      LumSpace.sm, LumSize.screenGutter, LumSpace.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: LumCircleButton(
                          icon: PhosphorIcons.caretLeft(),
                          label: HymnStrings.back,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                      const SizedBox(height: LumSpace.lg),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: LumSpace.xs),
                        child: Semantics(
                          header: true,
                          child: Text(HymnStrings.favouritesTitle,
                              style: LumText.largeTitle
                                  .copyWith(color: c.textPrimary)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              favoritesAsync.when(
                data: (favorites) {
                  if (favorites.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.all(LumSize.screenGutter),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ExcludeSemantics(
                              child: Lottie.asset('heart-pop'.lottie,
                                  width: 128, height: 128),
                            ),
                            Text(HymnStrings.noFavourites,
                                style: LumText.title2
                                    .copyWith(color: c.textPrimary)),
                            const SizedBox(height: LumSpace.sm),
                            Text(HymnStrings.noFavouritesBody,
                                textAlign: TextAlign.center,
                                style: LumText.callout
                                    .copyWith(color: c.textSecondary)),
                          ],
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        LumSize.screenGutter, 0, LumSize.screenGutter, 48),
                    sliver: DecoratedSliver(
                      decoration: LumGroupCard.decoration(c),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final favorite = favorites[index];
                            final hymn = favorite.hymn;
                            final stanzas = hymn.lyrics.stanzas;
                            return HymnListTile(
                              number: hymn.number.toString(),
                              title: hymn.title,
                              subtitle: stanzas.isEmpty
                                  ? null
                                  : stanzas.first.text.split('\n').first,
                              isFavorited: true,
                              showDivider: index < favorites.length - 1,
                              borderRadius: HymnListTile.edgeRadius(
                                  index, favorites.length),
                              onToggleFavorite: () {
                                final id = hymn.id!;
                                ref
                                    .read(favoritesProvider.notifier)
                                    .toggle(id, favorite.language);
                              },
                              onTap: () {
                                // Open the hymn in the language it was
                                // favorited in so the reader matches the
                                // saved translation.
                                ref.read(languageProvider.notifier).state =
                                    favorite.language;
                                final hymnId = hymn.id!;
                                context.router
                                    .push(HymnDetailRoute(hymnId: hymnId));
                              },
                            );
                          },
                          childCount: favorites.length,
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(HymnStrings.loadError,
                        style: LumText.body.copyWith(color: c.textSecondary)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
