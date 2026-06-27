import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/theme/app_colors.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/core/utils/extensions/string_extensions.dart';
import 'package:openbaptisthymnal/core/utils/toast_helper.dart';
import 'package:openbaptisthymnal/features/hymn/model/stanza.dart';
import 'package:openbaptisthymnal/features/hymn/providers/hymnal_provider.dart';
import 'package:openbaptisthymnal/features/hymn/ui/viewmodels/hymns_viewmodel.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/hymn_list_tile.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/language_toggle.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/search_bar_widget.dart';

/// Home tab screen - Shows the main hymn list
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
    final colorScheme = Theme.of(context).colorScheme;

    // Keep the scroll-button state in sync on both scroll and content-size
    // changes (the latter fires when the hymn list finishes loading).
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
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    }

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
                // Greeting + search + language toggle float together: they
                // slide away on scroll-down and snap back on any scroll-up.
                SliverFloatingHeader(
                  child: ColoredBox(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: _HomeHeader(
                            count: hymnsAsync.valueOrNull?.length,
                            onFavorites: () =>
                                context.router.push(const FavoritesTabRoute()),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: SearchBarWidget(
                            controller: searchController,
                            onChanged: (value) =>
                                searchQuery.value = value.toLowerCase(),
                            onFilterTap: () => ToastHelper.info(
                                context, 'Filtering will be available soon'),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          child: LanguageToggle(
                            selectedLanguage: currentLanguage,
                            onLanguageChanged: (language) => ref
                                .read(hymnsViewModelProvider.notifier)
                                .changeLanguage(language),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Hymn list
                hymnsAsync.when(
                  data: (hymns) {
                    final query = searchQuery.value;
                    final filteredHymns = query.isEmpty
                        ? hymns
                        : hymns.where((hymn) {
                            final title =
                                (hymn.title as String?)?.toLowerCase() ?? '';
                            final number = hymn.number.toString();

                            /// make the lyrics and stanzas searchable
                            final chorus =
                                (hymn.lyrics.chorus)?.toLowerCase() ?? '';
                            final stanzas =
                                (hymn.lyrics.stanzas as List<Stanza>?)?.map(
                                        (stanza) =>
                                            stanza.text.toLowerCase()) ??
                                    [];
                            return title.contains(query) ||
                                number.contains(query) ||
                                chorus.contains(query) ||
                                stanzas.any((stanza) => stanza.contains(query));
                          }).toList();

                    if (filteredHymns.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            children: [
                              Lottie.asset(
                                'empty-state'.lottie,
                                width: 200,
                                height: 200,
                              ),
                              Text(
                                'No hymns found',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                  'We couldn\'t find any hymns matching "$query". Try searching by title, hymn number, or lyrics.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: Theme.of(context).hintColor),
                                ),
                              ),
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
                            final hymn = filteredHymns[index];
                            final number = hymn.number.toString();
                            final title = hymn.title;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: HymnListTile(
                                number: number,
                                title: title,
                                onTap: () {
                                  // Use the ID if available (English hymnal),
                                  // otherwise fall back to the padded number.
                                  if (hymn.id != null) {
                                    context.router.push(
                                      HymnDetailRoute(hymnId: hymn.id!),
                                    );
                                  } else {
                                    final paddedId =
                                        'hymn_${number.padLeft(4, '0')}';
                                    context.router.push(
                                      HymnDetailRoute(hymnId: paddedId),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                          childCount: filteredHymns.length,
                        ),
                      ),
                    );
                  },
                  loading: () => SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  error: (error, stack) => SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load hymns',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () =>
                                ref.invalidate(hymnsViewModelProvider),
                            child: const Text('Retry'),
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

        // One-tap jump to top/bottom — flips direction by scroll position and
        // hides when the list is short enough to fit on screen.
        Positioned(
          right: 16,
          bottom: 100,
          child: AnimatedOpacity(
            opacity: canScroll.value ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !canScroll.value,
              child: _ScrollFab(atTop: atTop.value, onTap: jumpToEdge),
            ),
          ),
        ),
      ],
    );
  }
}

/// Small circular button that jumps the list to the top or bottom. Its arrow
/// flips: down when near the top, up when scrolled away from it.
class _ScrollFab extends StatelessWidget {
  const _ScrollFab({required this.atTop, required this.onTap});

  final bool atTop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.secondary,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              atTop ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
              key: ValueKey(atTop),
              color: AppColors.primaryDark,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen title with a quiet count subtitle, plus a circular tonal shortcut to
/// favorites — a small, contained affordance rather than a bare floating icon.
class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.count, required this.onFavorites});

  final int? count;
  final VoidCallback onFavorites;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor =
        isDark ? AppColors.neutral500 : AppColors.primary400;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hymns',
                style: AppTextStyles.headlineLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (count != null && count! > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '$count hymns',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: subtitleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
        _CircleIconButton(
          tooltip: 'Favorites',
          icon: CupertinoIcons.heart,
          onTap: onFavorites,
        ),
      ],
    );
  }
}

/// Small circular tonal icon button used in the home header.
class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.neutral800 : AppColors.secondary100;
    final border = isDark ? AppColors.neutral700 : AppColors.secondary200;
    final iconColor = isDark ? AppColors.secondary : AppColors.primary;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        shape: CircleBorder(side: BorderSide(color: border, width: 1)),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 20, color: iconColor),
          ),
        ),
      ),
    );
  }
}
