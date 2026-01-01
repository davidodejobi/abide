import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:open_baptist_hymnal/data/models/stanza.dart';
import 'package:open_baptist_hymnal/utils/extensions/string_extensions.dart';

import '../../../providers/hymnal_provider.dart';
import '../../../utils/theme/theme.dart';
import '../../viewmodels/hymns_viewmodel.dart';
import '../../widgets/hymn_list_tile.dart';
import '../../widgets/language_toggle.dart';
import '../../widgets/search_bar_widget.dart';

/// Home tab screen - Shows the main hymn list
@RoutePage()
class HomeTabScreen extends ConsumerStatefulWidget {
  const HomeTabScreen({super.key});

  @override
  ConsumerState<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends ConsumerState<HomeTabScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final hymnsAsync = ref.watch(hymnsViewModelProvider);
    final currentLanguage = ref.watch(languageProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                    final title = (hymn.title as String?)?.toLowerCase() ?? '';
                    final number = hymn.number.toString();

                    /// make the lyrics and stanzas searchable
                    final chorus = (hymn.lyrics.chorus)?.toLowerCase() ?? '';
                    final stanzas = (hymn.lyrics.stanzas as List<Stanza>?)
                            ?.map((stanza) => stanza.text.toLowerCase()) ??
                        [];
                    return title.contains(_searchQuery) ||
                        number.contains(_searchQuery) ||
                        chorus.contains(_searchQuery) ||
                        stanzas.any((stanza) => stanza.contains(_searchQuery));
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'We couldn\'t find any hymns matching "$_searchQuery". Try searching by title, hymn number, or lyrics.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
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
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load hymns',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: colorScheme.onSurface,
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
    );
  }
}
