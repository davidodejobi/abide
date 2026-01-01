import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../providers/hymnal_provider.dart';
import '../../utils/extensions/num_extensions.dart';
import '../../utils/theme/theme.dart';
import '../viewmodels/hymns_viewmodel.dart';
import '../widgets/bottom_nav_bar/bottom_nav_bar.dart';
import '../widgets/hymn_list_tile.dart';
import '../widgets/language_toggle.dart';
import '../widgets/search_bar_widget.dart';

class HymnListPage extends HookConsumerWidget {
  const HymnListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentNavIndex = useState(0);
    final searchController = useTextEditingController();
    final searchQuery = useState('');

    final hymnsAsync = ref.watch(hymnsViewModelProvider);
    final currentLanguage = ref.watch(languageProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // Custom Header with greeting and profile
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello,',
                              style: AppTextStyles.headlineLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Welcome to Open Baptist Hymnal',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        // Profile icon
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.secondary,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.person,
                            size: 20,
                            color: colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Search bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: SearchBarWidget(
                      controller: searchController,
                      onChanged: (value) {
                        searchQuery.value = value.toLowerCase();
                      },
                      onFilterTap: () {
                        // TODO: Implement filter
                      },
                    ),
                  ),
                ),

                // Language toggle
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: LanguageToggle(
                      selectedLanguage: currentLanguage,
                      onLanguageChanged: (language) {
                        ref
                            .read(hymnsViewModelProvider.notifier)
                            .changeLanguage(language);
                      },
                    ),
                  ),
                ),

                // Hymn list
                hymnsAsync.when(
                  data: (hymns) {
                    log('hymns: $hymns');
                    // Filter hymns based on search query
                    final filteredHymns = searchQuery.value.isEmpty
                        ? hymns
                        : hymns.where((hymn) {
                            final title =
                                (hymn.title as String?)?.toLowerCase() ?? '';
                            final number = hymn.number.toString();
                            return title.contains(searchQuery.value) ||
                                number.contains(searchQuery.value);
                          }).toList();

                    if (filteredHymns.isEmpty) {
                      return const SliverFillRemaining(
                        child: Center(
                          child: Text('No hymns found'),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
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
                                  // TODO: Navigate to hymn detail
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
                          16.h,
                          Text(
                            'Failed to load hymns',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          8.h,
                          TextButton(
                            onPressed: () {
                              ref.invalidate(hymnsViewModelProvider);
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Bottom navigation bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AdaptiveBottomNavBar(
                tabs: [
                  AdaptiveBottomNavTab(
                    label: 'Home',
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home_rounded,
                    glowColor: colorScheme.primary,
                  ),
                  AdaptiveBottomNavTab(
                    label: 'Favorites',
                    icon: Icons.favorite_outline,
                    selectedIcon: Icons.favorite_rounded,
                    glowColor: colorScheme.primary,
                  ),
                  AdaptiveBottomNavTab(
                    label: 'Settings',
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings_rounded,
                    glowColor: colorScheme.primary,
                  ),
                ],
                selectedIndex: currentNavIndex.value,
                onTabSelected: (index) {
                  currentNavIndex.value = index;
                },
                indicatorColor: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
