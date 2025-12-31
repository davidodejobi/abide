import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/hymnal_provider.dart';
import '../../utils/theme/theme.dart';
import '../viewmodels/hymns_viewmodel.dart';
import '../widgets/bottom_nav_bar/bottom_nav_bar.dart';
import '../widgets/hymn_list_tile.dart';
import '../widgets/language_toggle.dart';
import '../widgets/search_bar_widget.dart';

class HymnListPage extends ConsumerStatefulWidget {
  const HymnListPage({super.key});

  @override
  ConsumerState<HymnListPage> createState() => _HymnListPageState();
}

class _HymnListPageState extends ConsumerState<HymnListPage> {
  int _currentNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hymnsAsync = ref.watch(hymnsViewModelProvider);
    final currentLanguage = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
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
                                color: AppColors.neutral600,
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
                              color: AppColors.secondary,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 20,
                            color: AppColors.secondary,
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
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
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
                    // Filter hymns based on search query
                    final filteredHymns = _searchQuery.isEmpty
                        ? hymns
                        : hymns.where((hymn) {
                            final title =
                                (hymn['title'] as String?)?.toLowerCase() ?? '';
                            final number = hymn['number']?.toString() ?? '';
                            return title.contains(_searchQuery) ||
                                number.contains(_searchQuery);
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
                            final number = hymn['number']?.toString() ?? '';
                            final title = hymn['title'] as String? ?? '';

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
                  loading: () => const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  error: (error, stack) => SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load hymns',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.neutral800,
                            ),
                          ),
                          const SizedBox(height: 8),
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
                tabs: const [
                  AdaptiveBottomNavTab(
                    label: 'Home',
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home_rounded,
                    glowColor: AppColors.primary,
                  ),
                  AdaptiveBottomNavTab(
                    label: 'Favorites',
                    icon: Icons.favorite_outline,
                    selectedIcon: Icons.favorite_rounded,
                    glowColor: AppColors.primary,
                  ),
                  AdaptiveBottomNavTab(
                    label: 'Settings',
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings_rounded,
                    glowColor: AppColors.primary,
                  ),
                ],
                selectedIndex: _currentNavIndex,
                onTabSelected: (index) {
                  setState(() {
                    _currentNavIndex = index;
                  });
                },
                indicatorColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
