import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/theme/app_colors.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/core/theme/font_scale_provider.dart';
import 'package:openbaptisthymnal/core/utils/extensions/context_extensions.dart';
import 'package:openbaptisthymnal/core/utils/extensions/num_extensions.dart';
import 'package:openbaptisthymnal/core/utils/extensions/string_extensions.dart';
import 'package:openbaptisthymnal/core/utils/toast_helper.dart';
import 'package:openbaptisthymnal/core/widgets/split_orientation_toggle.dart';
import 'package:openbaptisthymnal/core/widgets/split_pane.dart';
import 'package:openbaptisthymnal/features/hymn/model/language_pack.dart';
import 'package:openbaptisthymnal/features/hymn/providers/favorites_provider.dart';
import 'package:openbaptisthymnal/features/hymn/providers/hymnal_provider.dart';
import 'package:openbaptisthymnal/features/hymn/ui/viewmodels/hymns_viewmodel.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/hymn_picker_inline.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/hymn_view.dart';
import 'package:openbaptisthymnal/features/settings/ui/widgets/font_size_control.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:vector_graphics/vector_graphics_compat.dart';

/// Two-pack default — the only languages currently shipped. If the project
/// ever grows beyond two, swap this for a lookup against `HymnalIndex.orders`.
const List<String> _availableLanguages = ['en', 'yo'];

String _otherLanguage(String current) => current == 'yo'
    ? 'en'
    : current == 'en'
        ? 'yo'
        : 'en';

/// Local split state for the hymn detail page. Ephemeral — gone on navigation.
class _HymnSplitState {
  const _HymnSplitState({
    required this.isOpen,
    required this.orientation,
    required this.secondaryHymnId,
    required this.secondaryLanguage,
  });

  final bool isOpen;
  final SplitOrientation orientation;
  final String? secondaryHymnId;
  final String? secondaryLanguage;

  static const initial = _HymnSplitState(
    isOpen: false,
    orientation: SplitOrientation.vertical,
    secondaryHymnId: null,
    secondaryLanguage: null,
  );

  _HymnSplitState copyWith({
    bool? isOpen,
    SplitOrientation? orientation,
    String? secondaryHymnId,
    String? secondaryLanguage,
    bool clearSecondary = false,
  }) =>
      _HymnSplitState(
        isOpen: isOpen ?? this.isOpen,
        orientation: orientation ?? this.orientation,
        secondaryHymnId:
            clearSecondary ? null : (secondaryHymnId ?? this.secondaryHymnId),
        secondaryLanguage: clearSecondary
            ? null
            : (secondaryLanguage ?? this.secondaryLanguage),
      );
}

@RoutePage()
class HymnDetailPage extends HookConsumerWidget {
  final String hymnId;

  const HymnDetailPage({super.key, required this.hymnId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(hymnDetailProvider(hymnId));
    final language = ref.watch(languageProvider);
    final isFavorited = ref.watch(
      favoritesProvider.select(
        (ids) => ids.contains(favoriteKey(language, hymnId)),
      ),
    );
    final textScale = ref.watch(fontScaleProvider).scale;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final split = useState(_HymnSplitState.initial);

    final backgroundColor =
        isDark ? AppColors.neutral900 : AppColors.neutral100;
    final numberColor = isDark ? AppColors.neutral700 : AppColors.neutral300;

    void openSplit() {
      // Auto-bilingual: drop the same hymn into the secondary pane in the
      // other language so the bilingual reading is one tap away.
      split.value = _HymnSplitState(
        isOpen: true,
        orientation: SplitOrientation.vertical,
        secondaryHymnId: hymnId,
        secondaryLanguage: _otherLanguage(language),
      );
    }

    void closeSplit() {
      split.value = _HymnSplitState.initial;
    }

    void onPickSecondary(String pickedId, String pickedLanguage) {
      split.value = split.value.copyWith(
        secondaryHymnId: pickedId,
        secondaryLanguage: pickedLanguage,
      );
    }

    void clearSecondary() {
      // Drops back to the picker so the user can choose another hymn.
      split.value = split.value.copyWith(clearSecondary: true);
    }

    void onSecondaryLanguageChanged(String lang) {
      // In the picker the user just wants to browse another language pack.
      split.value = split.value.copyWith(secondaryLanguage: lang);
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const AutoLeadingButton(),
        title: split.value.isOpen
            ? SplitOrientationToggle(
                orientation: split.value.orientation,
                onChanged: (o) =>
                    split.value = split.value.copyWith(orientation: o),
              )
            : null,
        centerTitle: true,
        // In split mode, essentials move to the AppBar so the floating bottom
        // bar doesn't overlap the cramped panes.
        actions: split.value.isOpen
            ? [
                IconButton(
                  tooltip: 'Lyric size',
                  icon: Icon(PhosphorIcons.textAa()),
                  onPressed: () => _showFontSizeSheet(context),
                ),
                IconButton(
                  tooltip: isFavorited ? 'Unfavorite' : 'Favorite',
                  icon: Icon(
                    isFavorited
                        ? PhosphorIcons.heart(PhosphorIconsStyle.fill)
                        : PhosphorIcons.heart(),
                    color: isFavorited ? Colors.red : null,
                  ),
                  onPressed: () => ref
                      .read(favoritesProvider.notifier)
                      .toggle(hymnId, language),
                ),
                IconButton(
                  tooltip: 'Close split',
                  icon: Icon(PhosphorIcons.x()),
                  onPressed: closeSplit,
                ),
                const SizedBox(width: 4),
              ]
            : null,
      ),
      body: detailAsync.when(
        data: (data) {
          final translations = data['translations'] as Map;
          if (translations.isEmpty) {
            return const Center(child: Text('No translation found'));
          }
          final primary = translations.values.first as HymnTranslation;
          final hymnNumber = primary.number.toString().padLeft(3, '0');

          void shareText(String body) {
            final trimmed = body.trim();
            if (trimmed.isEmpty) return;
            context.router.push(
              ShareCardRoute(
                hymnNumber: hymnNumber,
                title: primary.title,
                body: trimmed,
              ),
            );
          }

          final isSplit = split.value.isOpen;
          final primaryView = HymnView(
            translation: primary,
            textScale: textScale,
            onShare: shareText,
            languageLabel: isSplit ? language : null,
            bottomExtraSpace: isSplit ? 16 : 100,
            titleRightInset: isSplit ? 0 : context.screenSize.width * 0.4,
            compact: isSplit,
          );

          if (isSplit) {
            // Split mode is intentionally stripped of decorations: no big
            // number watermark, no floating bottom bar. Just panes + AppBar
            // actions for the essentials.
            return SplitPane(
              orientation: split.value.orientation,
              primary: primaryView,
              secondary: _SecondaryHymnPane(
                hymnId: split.value.secondaryHymnId,
                language:
                    split.value.secondaryLanguage ?? _otherLanguage(language),
                textScale: textScale,
                onShare: shareText,
                onPickHymn: onPickSecondary,
                onLanguageChanged: onSecondaryLanguageChanged,
                onChange: clearSecondary,
              ),
            );
          }

          // Single-pane: keep the existing rich layout — watermark + floating
          // bottom bar — fully intact.
          return Stack(
            children: [
              Positioned(
                top: 0,
                right: 16,
                child: Text(
                  hymnNumber,
                  style: AppTextStyles.hymnNumber(color: numberColor)
                      .copyWith(fontSize: 80, height: 1.0),
                ),
              ),
              primaryView,
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: _BottomBar(
                  isDark: isDark,
                  isFavorited: isFavorited,
                  onShare: () => shareText([
                    for (final s in primary.lyrics.stanzas) s.text,
                    if (primary.lyrics.chorus?.isNotEmpty ?? false)
                      primary.lyrics.chorus!,
                  ].join('\n\n')),
                  onLanguageSwitch: () => ToastHelper.info(
                      context, 'Language switch will be available soon'),
                  onSplit: openSplit,
                  splitActive: split.value.isOpen,
                  onFontSize: () => _showFontSizeSheet(context),
                  onToggleFavorite: () => ref
                      .read(favoritesProvider.notifier)
                      .toggle(hymnId, language),
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

/// Secondary pane: shows either the picker (when no hymn is selected) or a
/// [HymnView] rendering the chosen hymn. Owns a small header with a × to drop
/// back to the picker.
class _SecondaryHymnPane extends ConsumerWidget {
  const _SecondaryHymnPane({
    required this.hymnId,
    required this.language,
    required this.textScale,
    required this.onShare,
    required this.onPickHymn,
    required this.onLanguageChanged,
    required this.onChange,
  });

  final String? hymnId;
  final String language;
  final double textScale;
  final void Function(String body) onShare;
  final void Function(String hymnId, String language) onPickHymn;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (hymnId == null) {
      return HymnPickerInline(
        language: language,
        availableLanguages: _availableLanguages,
        onLanguageChanged: onLanguageChanged,
        onSelected: onPickHymn,
      );
    }
    final translationAsync =
        ref.watch(hymnInLanguageProvider(HymnInLanguageKey(hymnId!, language)));
    return translationAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load hymn: $e')),
      data: (translation) {
        if (translation == null) {
          return _PaneMessage(
            message: 'This hymn isn\'t available in $language yet.',
            actionLabel: 'Pick another',
            onAction: onChange,
          );
        }
        return HymnView(
          translation: translation,
          textScale: textScale,
          onShare: onShare,
          languageLabel: language,
          bottomExtraSpace: 16,
          compact: true,
          trailingHeader: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onChange,
                  icon: Icon(PhosphorIcons.arrowsLeftRight(), size: 18),
                  label: const Text('Change'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PaneMessage extends StatelessWidget {
  const _PaneMessage({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(message, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.isDark,
    required this.isFavorited,
    required this.onShare,
    required this.onLanguageSwitch,
    required this.onSplit,
    required this.onFontSize,
    required this.onToggleFavorite,
    this.splitActive = false,
  });

  final bool isDark;
  final bool isFavorited;
  final VoidCallback onShare;
  final VoidCallback onLanguageSwitch;
  final VoidCallback onSplit;
  final bool splitActive;
  final VoidCallback onFontSize;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.surfaceContainerDark : Colors.white)
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
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _BottomBarButton(
                  icon: 'share_out'.iconSvg,
                  onTap: onShare,
                  isDark: isDark,
                ),
                8.w,
                _BottomBarButton(
                  icon: 'share'.iconSvg,
                  onTap: onLanguageSwitch,
                  isDark: isDark,
                ),
                8.w,
                _BottomBarButton(
                  icon: 'split'.iconSvg,
                  onTap: onSplit,
                  isDark: isDark,
                  isActive: splitActive,
                ),
                8.w,
                _FontSizeBarButton(onTap: onFontSize, isDark: isDark),
                8.w,
                _BottomBarButton(
                  icon: isFavorited ? 'heart_filled'.iconSvg : 'heart'.iconSvg,
                  onTap: onToggleFavorite,
                  isDark: isDark,
                  isActive: isFavorited,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the reader font-size control in a bottom sheet. Lyrics behind the
/// sheet resize live because the page watches [fontScaleProvider].
void _showFontSizeSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lyric size',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              const FontSizeControl(),
            ],
          ),
        ),
      );
    },
  );
}

class _FontSizeBarButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;

  const _FontSizeBarButton({required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? AppColors.neutral850 : AppColors.secondary50,
          shape: BoxShape.circle,
        ),
        child: Icon(
          PhosphorIcons.textAa(),
          size: 22,
          color: isDark ? AppColors.neutral100 : AppColors.primaryDark,
        ),
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
