import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/widgets/lum_button.dart';
import 'package:openbaptisthymnal/core/widgets/lum_chip.dart';
import 'package:openbaptisthymnal/core/widgets/lum_circle_button.dart';
import 'package:openbaptisthymnal/core/widgets/lum_group_card.dart';
import 'package:openbaptisthymnal/features/hymn/model/language_pack.dart';
import 'package:openbaptisthymnal/features/hymn/providers/enabled_hymn_languages_provider.dart';
import 'package:openbaptisthymnal/features/hymn/providers/favorites_provider.dart';
import 'package:openbaptisthymnal/features/hymn/providers/hymnal_provider.dart';
import 'package:openbaptisthymnal/features/hymn/ui/hymn_strings.dart';
import 'package:openbaptisthymnal/features/hymn/ui/viewmodels/hymns_viewmodel.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/hymn_languages_sheet.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/hymn_list_tile.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/language_toggle.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/search_bar_widget.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// The Songs tab (Figma M3-06): title, search, language chips and the hymn
/// list. While searching, the same list narrows; when nothing matches the
/// traveller rests (M3-11).
@RoutePage()
class HomeTabScreen extends HookConsumerWidget {
  const HomeTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useAutomaticKeepAlive();

    final searchController = useTextEditingController();
    final searchQuery = useState('');
    final scrollController = useScrollController();
    // Drives the floating scroll button: only shown when the list can scroll,
    // and its direction flips depending on whether we're near the top.
    final canScroll = useState(false);
    final atTop = useState(true);

    final hymnsAsync = ref.watch(hymnsViewModelProvider);
    final currentLanguage = ref.watch(languageProvider);
    final favourites = ref.watch(favoritesProvider);
    final enabled = ref.watch(enabledHymnLanguagesProvider);
    final c = context.lum;

    // ScrollMetricsNotification can arrive *during* layout, so defer the state
    // write to the next frame to avoid "Build scheduled during frame".
    void syncFromMetrics(ScrollMetrics metrics) {
      final scrollable = metrics.maxScrollExtent > 0;
      final nearTop = metrics.pixels <= 50;
      if (canScroll.value == scrollable && atTop.value == nearTop) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        canScroll.value = scrollable;
        atTop.value = nearTop;
      });
    }

    void jumpToEdge() {
      if (!scrollController.hasClients) return;
      final target =
          atTop.value ? scrollController.position.maxScrollExtent : 0.0;
      scrollController.animateTo(
        target,
        duration: LumMotion.slow,
        curve: Curves.easeInOut,
      );
    }

    String idOf(HymnTranslation hymn) =>
        hymn.id ?? 'hymn_${hymn.number.toString().padLeft(4, '0')}';

    return Stack(
      children: [
        NotificationListener<ScrollMetricsNotification>(
          onNotification: (n) {
            syncFromMetrics(n.metrics);
            return false;
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              syncFromMetrics(n.metrics);
              return false;
            },
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(LumSize.screenGutter + 4,
                        LumSpace.xxxl, LumSize.screenGutter + 4, LumSpace.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(HymnStrings.eyebrow(enabled),
                            style: LumText.roadLabelCaps11
                                .copyWith(color: c.textSecondary)),
                        const SizedBox(height: LumSpace.sm),
                        Semantics(
                          header: true,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(HymnStrings.songs,
                                maxLines: 1,
                                style: LumText.roadDisplayMedium56
                                    .copyWith(color: c.textPrimary)),
                          ),
                        ),
                        const SizedBox(height: LumSpace.lg),
                        SearchBarWidget(
                          controller: searchController,
                          onChanged: (value) =>
                              searchQuery.value = value.trim().toLowerCase(),
                        ),
                        const SizedBox(height: LumSpace.lg),
                        LanguageToggle(
                          selectedLanguage: currentLanguage,
                          onLanguageChanged: (language) => ref
                              .read(hymnsViewModelProvider.notifier)
                              .changeLanguage(language),
                          // One language on: no chip to switch between.
                          languages: enabled.length > 1
                              ? [
                                  for (final code in enabled)
                                    LanguageOption(
                                        code: code,
                                        label: HymnStrings.languageName(code)),
                                ]
                              : const [],
                          trailing: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              LumChip(
                                label: HymnStrings.favourites,
                                icon: PhosphorIcons.heart(),
                                onTap: () => context.router
                                    .push(const FavoritesTabRoute()),
                              ),
                              LumChip(
                                label: HymnStrings.addLanguage,
                                onTap: () => showHymnLanguagesSheet(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                hymnsAsync.when(
                  data: (hymns) {
                    final query = searchQuery.value;
                    final filtered = query.isEmpty
                        ? hymns
                        : hymns.where((hymn) {
                            final title = hymn.title.toLowerCase();
                            final number = hymn.number.toString();
                            // make the lyrics and stanzas searchable
                            final chorus =
                                (hymn.lyrics.chorus)?.toLowerCase() ?? '';
                            return title.contains(query) ||
                                number.contains(query) ||
                                chorus.contains(query) ||
                                hymn.lyrics.stanzas.any((stanza) =>
                                    stanza.text.toLowerCase().contains(query));
                          }).toList();

                    if (filtered.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: _NoResults(query: searchController.text.trim()),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                          LumSize.screenGutter, 0, LumSize.screenGutter, 120),
                      sliver: DecoratedSliver(
                        decoration: LumGroupCard.decoration(c),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final hymn = filtered[index];
                              final id = idOf(hymn);
                              final stanzas = hymn.lyrics.stanzas;
                              final firstLine = stanzas.isEmpty
                                  ? null
                                  : stanzas.first.text.split('\n').first;
                              return HymnListTile(
                                number: hymn.number.toString(),
                                title: hymn.title,
                                subtitle: firstLine,
                                isFavorited: favourites
                                    .contains(favoriteKey(currentLanguage, id)),
                                showDivider: index < filtered.length - 1,
                                borderRadius: HymnListTile.edgeRadius(
                                    index, filtered.length),
                                onToggleFavorite: () => ref
                                    .read(favoritesProvider.notifier)
                                    .toggle(id, currentLanguage),
                                onTap: () => context.router
                                    .push(HymnDetailRoute(hymnId: id)),
                              );
                            },
                            childCount: filtered.length,
                          ),
                        ),
                      ),
                    );
                  },
                  loading: () => SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(color: c.textSecondary),
                    ),
                  ),
                  error: (error, stack) => SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(HymnStrings.loadError,
                              style:
                                  LumText.body.copyWith(color: c.textPrimary)),
                          const SizedBox(height: LumSpace.lg),
                          SizedBox(
                            width: 220,
                            child: LumButton(
                              label: HymnStrings.retry,
                              kind: LumButtonKind.secondary,
                              onPressed: () =>
                                  ref.invalidate(hymnsViewModelProvider),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // One-tap jump to top/bottom: flips direction by scroll position and
        // hides when the list is short enough to fit on screen.
        Positioned(
          right: LumSize.screenGutter,
          bottom: 100,
          child: AnimatedOpacity(
            opacity: canScroll.value ? 1 : 0,
            duration: LumMotion.fast,
            child: IgnorePointer(
              ignoring: !canScroll.value,
              child: LumCircleButton(
                icon: atTop.value
                    ? PhosphorIcons.caretDown()
                    : PhosphorIcons.caretUp(),
                label: atTop.value
                    ? HymnStrings.scrollToBottom
                    : HymnStrings.scrollToTop,
                onPressed: jumpToEdge,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Nothing matched (Figma M3-11): the resting traveller, what was searched,
/// and a way forward.
class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          LumSize.screenGutter + 4, LumSpace.xl, LumSize.screenGutter + 4, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ExcludeSemantics(
            child: Image.asset(
              'assets/images/road/traveller_resting_${dark ? 'dark' : 'light'}.png',
              height: 96,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: LumSpace.lg),
          Semantics(
            header: true,
            child: Text(HymnStrings.noResults(query),
                textAlign: TextAlign.center,
                style: LumText.title1.copyWith(color: c.textPrimary)),
          ),
          const SizedBox(height: LumSpace.sm),
          Text(HymnStrings.noResultsHint,
              textAlign: TextAlign.center,
              style: LumText.callout.copyWith(color: c.textSecondary)),
        ],
      ),
    );
  }
}
