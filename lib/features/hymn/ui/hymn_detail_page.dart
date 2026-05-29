import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/theme/app_colors.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/core/utils/extensions/context_extensions.dart';
import 'package:openbaptisthymnal/core/utils/extensions/num_extensions.dart';
import 'package:openbaptisthymnal/core/utils/extensions/string_extensions.dart';
import 'package:openbaptisthymnal/core/utils/toast_helper.dart';
import 'package:openbaptisthymnal/features/hymn/model/language_pack.dart';
import 'package:openbaptisthymnal/features/hymn/providers/favorites_provider.dart';
import 'package:openbaptisthymnal/features/hymn/ui/viewmodels/hymns_viewmodel.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/stanza_card.dart';
import 'package:vector_graphics/vector_graphics_compat.dart';

@RoutePage()
class HymnDetailPage extends HookConsumerWidget {
  final String hymnId;

  const HymnDetailPage({super.key, required this.hymnId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch hymn details
    final detailAsync = ref.watch(hymnDetailProvider(hymnId));
    final isFavorited = ref.watch(
      favoritesProvider.select((ids) => ids.contains(hymnId)),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Define colors based on the design tokens
    final backgroundColor =
        isDark ? AppColors.neutral900 : AppColors.neutral100;
    final primaryTextColor =
        isDark ? AppColors.neutral100 : AppColors.neutral700;
    final numberColor = isDark ? AppColors.neutral700 : AppColors.neutral300;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const AutoLeadingButton(),
      ),
      body: detailAsync.when(
        data: (data) {
          // Extract data
          // Assuming data structure based on previous code
          final translations = data['translations'] as Map;
          if (translations.isEmpty) {
            return const Center(child: Text('No translation found'));
          }
          final firstTranslation = translations.values.first as HymnTranslation;
          final title = firstTranslation.title;
          final stanzas = firstTranslation.lyrics.stanzas;
          final chorus = firstTranslation.lyrics.chorus;
          final hasChorus = chorus != null && chorus.isNotEmpty;

          // Use hymnId as number for now, or extract if available
          final hymnNumber = firstTranslation.number.toString().padLeft(3, '0');

          void shareText(String body) {
            final trimmed = body.trim();
            if (trimmed.isEmpty) return;
            context.router.push(
              ShareCardRoute(
                hymnNumber: hymnNumber,
                title: title,
                body: trimmed,
              ),
            );
          }

          return 1.isEven
              ? const SingleChildScrollView(
                  child: Column(),
                )
              : Stack(
                  children: [
                    // Huge Number Watermark
                    Positioned(
                      top: 0,
                      right: 16,
                      child: Text(
                        hymnNumber,
                        style: AppTextStyles.hymnNumber(color: numberColor)
                            .copyWith(
                          fontSize: 80,
                          height: 1.0,
                        ),
                      ),
                    ),

                    // Content
                    CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                                16, 0, context.screenSize.width * 0.4, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: AppTextStyles.headlineLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: primaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Stanza List
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (hasChorus) {
                                  if (index == 0) {
                                    return StanzaCard(
                                      text: stanzas[0].text,
                                      displayIndex: 1,
                                      onShare: shareText,
                                    );
                                  } else if (index == 1) {
                                    return StanzaCard(
                                      text: chorus,
                                      displayIndex: 0,
                                      isChorus: true,
                                      onShare: shareText,
                                    );
                                  } else if (index - 1 < stanzas.length) {
                                    return StanzaCard(
                                      text: stanzas[index - 1].text,
                                      displayIndex: index,
                                      onShare: shareText,
                                    );
                                  }
                                  return null;
                                } else {
                                  if (index < stanzas.length) {
                                    return StanzaCard(
                                      text: stanzas[index].text,
                                      displayIndex: index + 1,
                                      onShare: shareText,
                                    );
                                  }
                                  return null;
                                }
                              },
                              childCount: hasChorus
                                  ? stanzas.length + 1
                                  : stanzas.length,
                            ),
                          ),
                        ),

                        // Bottom Spacer
                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ),

                    // Floating Bottom Bar
                    Positioned(
                      bottom: 32,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                            child: Container(
                              height: 64,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              decoration: BoxDecoration(
                                color: (isDark
                                        ? AppColors.surfaceContainerDark
                                        : Colors.white)
                                    .withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: (isDark ? Colors.white : Colors.black)
                                      .withValues(alpha: 0.1),
                                  width: 0.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  )
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _BottomBarButton(
                                    icon: 'share_out'.iconSvg,
                                    onTap: () => shareText([
                                      for (final s in stanzas) s.text,
                                      if (hasChorus) chorus,
                                    ].join('\n\n')),
                                    isDark: isDark,
                                  ),
                                  8.w,
                                  _BottomBarButton(
                                    icon: 'split'.iconSvg,
                                    onTap: () => ToastHelper.info(context,
                                        'Split view will be available soon'),
                                    isDark: isDark,
                                  ),
                                  8.w,
                                  _BottomBarButton(
                                    icon: isFavorited
                                        ? 'heart_filled'.iconSvg
                                        : 'heart'.iconSvg,
                                    onTap: () => ref
                                        .read(favoritesProvider.notifier)
                                        .toggle(hymnId),
                                    isDark: isDark,
                                    isActive: isFavorited,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _BottomBarButton extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;
  final bool isDark;
  final bool isActive;

  const _BottomBarButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isActive
        ? Colors.red
        : (isDark ? AppColors.neutral100 : AppColors.primaryDark);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.neutral850 : AppColors.secondary50,
          shape: BoxShape.circle,
        ),
        child: VectorGraphic(
          loader: AssetBytesLoader(icon),
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        ),
      ),
    );
  }
}
