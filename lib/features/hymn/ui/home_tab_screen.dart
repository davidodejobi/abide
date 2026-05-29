import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/theme/app_colors.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/core/utils/extensions/string_extensions.dart';
import 'package:openbaptisthymnal/core/utils/time_greeting.dart';
import 'package:openbaptisthymnal/core/utils/toast_helper.dart';
import 'package:openbaptisthymnal/features/hymn/model/stanza.dart';
import 'package:openbaptisthymnal/features/hymn/providers/hymnal_provider.dart';
import 'package:openbaptisthymnal/features/hymn/ui/viewmodels/hymns_viewmodel.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/hymn_list_tile.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/language_toggle.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/search_bar_widget.dart';
import 'package:openbaptisthymnal/features/onboarding/providers/onboarding_provider.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/widgets/hand_drawn_moon.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/widgets/hand_drawn_sun.dart';

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
                          child:
                              _HomeHeader(name: ref.watch(userNameProvider)),
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
                            final stanzas = (hymn.lyrics.stanzas
                                        as List<Stanza>?)
                                    ?.map((stanza) => stanza.text.toLowerCase()) ??
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

/// Greets the user by name with a clock-aware salutation, a hand-written accent
/// line, and a small self-drawing sun (day) or moon (night) doodle — carrying
/// the onboarding's warmth onto the home screen.
class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final greeting = TimeGreeting.now();
    final salutation =
        name == null ? '${greeting.greeting}.' : '${greeting.greeting}, $name';
    // Bright gold reads well on dark charcoal; a deep gold keeps the accent and
    // doodle legible on the light cream background instead of washing out.
    final accentColor = isDark ? AppColors.secondary : AppColors.secondaryDark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                salutation,
                style: AppTextStyles.headlineLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Hand-written accent — the subtle onboarding voice on home.
              Text(
                greeting.accent,
                style: AppTextStyles.doodleLabel(color: accentColor),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Self-drawing celestial doodle — a quiet day/night accent.
        SizedBox(
          width: 64,
          height: 48,
          child: greeting.isNight
              ? HandDrawnMoon(
                  size: const Size(64, 48),
                  color: accentColor,
                  strokeWidth: 1.8,
                  duration: const Duration(milliseconds: 1200),
                  startDelay: const Duration(milliseconds: 200),
                )
              : HandDrawnSun(
                  size: const Size(64, 48),
                  color: accentColor,
                  strokeWidth: 1.8,
                  duration: const Duration(milliseconds: 1200),
                  startDelay: const Duration(milliseconds: 200),
                ),
        ),
      ],
    );
  }
}
