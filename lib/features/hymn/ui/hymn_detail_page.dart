import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/theme/font_scale_provider.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/widgets/lum_circle_button.dart';
import 'package:openbaptisthymnal/core/widgets/lum_glass_bar.dart';
import 'package:openbaptisthymnal/core/widgets/lum_page_background.dart';
import 'package:openbaptisthymnal/core/widgets/split_orientation_toggle.dart';
import 'package:openbaptisthymnal/core/widgets/split_pane.dart';
import 'package:openbaptisthymnal/features/hymn/model/language_pack.dart';
import 'package:openbaptisthymnal/features/hymn/providers/favorites_provider.dart';
import 'package:openbaptisthymnal/features/hymn/providers/hymnal_provider.dart';
import 'package:openbaptisthymnal/features/hymn/ui/hymn_strings.dart';
import 'package:openbaptisthymnal/features/hymn/ui/viewmodels/hymns_viewmodel.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/hymn_picker_inline.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/hymn_view.dart';
import 'package:openbaptisthymnal/features/settings/ui/widgets/text_size_sheet.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Two-pack default: the only languages currently shipped. If the project
/// ever grows beyond two, swap this for a lookup against `HymnalIndex.orders`.
const List<String> _availableLanguages = ['en', 'yo'];

String _otherLanguage(String current) => current == 'yo'
    ? 'en'
    : current == 'en'
        ? 'yo'
        : 'en';

/// Local split state for the hymn detail page. Ephemeral: gone on navigation.
class _HymnSplitState {
  const _HymnSplitState({
    required this.isOpen,
    required this.orientation,
    required this.secondaryHymnId,
    required this.secondaryLanguage,
    this.secondaryIdLanguage,
  });

  final bool isOpen;
  final SplitOrientation orientation;
  final String? secondaryHymnId;
  final String? secondaryLanguage;

  /// Pack that [secondaryHymnId] is an id of (differs from the pane's
  /// language when the pane opened as the pair of the primary hymn).
  final String? secondaryIdLanguage;

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
    String? secondaryIdLanguage,
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
        secondaryIdLanguage: clearSecondary
            ? null
            : (secondaryIdLanguage ?? this.secondaryIdLanguage),
      );
}

/// A hymn (Figma M3-07, M3-08): the title, the lyrics in the reading style and
/// a glass bar of actions. Split view puts a second hymn beside it.
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
    final c = context.lum;
    final split = useState(_HymnSplitState.initial);
    final isSplit = split.value.isOpen;

    void openSplit() {
      // Auto-bilingual: drop the same hymn into the secondary pane in the
      // other language so the bilingual reading is one tap away.
      split.value = _HymnSplitState(
        isOpen: true,
        orientation: SplitOrientation.vertical,
        secondaryHymnId: hymnId,
        secondaryLanguage: _otherLanguage(language),
        secondaryIdLanguage: language,
      );
    }

    void toggleFavourite() =>
        ref.read(favoritesProvider.notifier).toggle(hymnId, language);
    void textSizeSheet() =>
        showTextSizeSheet(context, title: HymnStrings.lyricSize);
    void back() => Navigator.of(context).maybePop();

    final heartIcon = isFavorited
        ? PhosphorIcons.heart(PhosphorIconsStyle.fill)
        : PhosphorIcons.heart();
    final heartLabel =
        isFavorited ? HymnStrings.removeFavourite : HymnStrings.addFavourite;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LumPageBackground(
        child: SafeArea(
          bottom: false,
          child: detailAsync.when(
            data: (data) {
              final translations = data['translations'] as Map;
              if (translations.isEmpty) {
                return Column(children: [
                  _TopRow(onBack: back),
                  Expanded(
                    child: Center(
                      child: Text(HymnStrings.noTranslation,
                          style: LumText.body.copyWith(color: c.textSecondary)),
                    ),
                  ),
                ]);
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

              final primaryView = HymnView(
                translation: primary,
                textScale: textScale,
                onShare: shareText,
                languageLabel:
                    isSplit ? HymnStrings.languageName(language) : null,
                meta: isSplit
                    ? null
                    : '${HymnStrings.stanzas(primary.lyrics.stanzas.length)} · ${HymnStrings.languageName(language)}',
                bottomExtraSpace: isSplit ? LumSpace.lg : 160,
                compact: isSplit,
              );

              if (isSplit) {
                return Column(
                  children: [
                    _TopRow(
                      onBack: back,
                      center: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SplitOrientationToggle(
                          orientation: split.value.orientation,
                          onChanged: (o) => split.value =
                              split.value.copyWith(orientation: o),
                        ),
                      ),
                      trailing: [
                        LumCircleButton(
                          icon: PhosphorIcons.textAa(),
                          label: HymnStrings.textSize,
                          onPressed: textSizeSheet,
                        ),
                        LumCircleButton(
                          icon: heartIcon,
                          label: heartLabel,
                          onPressed: toggleFavourite,
                        ),
                        LumCircleButton(
                          icon: PhosphorIcons.x(),
                          label: HymnStrings.closeSplit,
                          onPressed: () =>
                              split.value = _HymnSplitState.initial,
                        ),
                      ],
                    ),
                    Expanded(
                      child: SplitPane(
                        orientation: split.value.orientation,
                        primary: primaryView,
                        secondary: _SecondaryHymnPane(
                          hymnId: split.value.secondaryHymnId,
                          idLanguage: split.value.secondaryIdLanguage,
                          language: split.value.secondaryLanguage ??
                              _otherLanguage(language),
                          textScale: textScale,
                          onShare: shareText,
                          onPickHymn: (id, lang) => split.value = split.value
                              .copyWith(
                                  secondaryHymnId: id,
                                  secondaryLanguage: lang,
                                  secondaryIdLanguage: lang),
                          onLanguageChanged: (lang) => split.value =
                              split.value.copyWith(secondaryLanguage: lang),
                          onChange: () => split.value =
                              split.value.copyWith(clearSecondary: true),
                        ),
                      ),
                    ),
                  ],
                );
              }

              // Single pane: the lyrics with a glass action bar floating over
              // the bottom, a sibling of the scrolling text.
              final bottom = MediaQuery.paddingOf(context).bottom;
              return Stack(
                children: [
                  Column(
                    children: [
                      _TopRow(onBack: back),
                      Expanded(child: primaryView),
                    ],
                  ),
                  Positioned(
                    left: LumSize.screenGutter,
                    right: LumSize.screenGutter,
                    bottom: bottom + LumSpace.lg,
                    child: LumGlassBar(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          LumCircleButton(
                            plain: true,
                            icon: PhosphorIcons.export(),
                            label: HymnStrings.share,
                            onPressed: () => shareText([
                              for (final s in primary.lyrics.stanzas) s.text,
                              if (primary.lyrics.chorus?.isNotEmpty ?? false)
                                primary.lyrics.chorus!,
                            ].join('\n\n')),
                          ),
                          LumCircleButton(
                            plain: true,
                            icon: PhosphorIcons.columns(),
                            label: HymnStrings.splitView,
                            onPressed: openSplit,
                          ),
                          LumCircleButton(
                            plain: true,
                            icon: PhosphorIcons.textAa(),
                            label: HymnStrings.textSize,
                            onPressed: textSizeSheet,
                          ),
                          LumCircleButton(
                            plain: true,
                            icon: heartIcon,
                            label: heartLabel,
                            onPressed: toggleFavourite,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => Column(children: [
              _TopRow(onBack: back),
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ]),
            error: (err, stack) => Column(children: [
              _TopRow(onBack: back),
              Expanded(
                child: Center(
                  child: Text(HymnStrings.loadError,
                      style: LumText.body.copyWith(color: c.textSecondary)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Back button on the left, optional centre and trailing controls.
class _TopRow extends StatelessWidget {
  const _TopRow({required this.onBack, this.center, this.trailing = const []});

  final VoidCallback onBack;
  final Widget? center;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          LumSize.screenGutter, LumSpace.sm, LumSize.screenGutter, 0),
      child: Row(
        children: [
          LumCircleButton(
            icon: PhosphorIcons.caretLeft(),
            label: HymnStrings.back,
            onPressed: onBack,
          ),
          Expanded(child: Center(child: center)),
          for (var i = 0; i < trailing.length; i++) ...[
            if (i > 0) const SizedBox(width: LumSpace.xs),
            trailing[i],
          ],
        ],
      ),
    );
  }
}

/// Secondary pane: shows either the picker (when no hymn is selected) or a
/// [HymnView] rendering the chosen hymn.
class _SecondaryHymnPane extends ConsumerWidget {
  const _SecondaryHymnPane({
    required this.hymnId,
    required this.idLanguage,
    required this.language,
    required this.textScale,
    required this.onShare,
    required this.onPickHymn,
    required this.onLanguageChanged,
    required this.onChange,
  });

  final String? hymnId;
  final String? idLanguage;
  final String language;
  final double textScale;
  final void Function(String body) onShare;
  final void Function(String hymnId, String language) onPickHymn;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lum;
    if (hymnId == null) {
      return HymnPickerInline(
        language: language,
        availableLanguages: _availableLanguages,
        onLanguageChanged: onLanguageChanged,
        onSelected: onPickHymn,
      );
    }
    final translationAsync = ref.watch(hymnInLanguageProvider(
        HymnInLanguageKey(hymnId!, language, idLanguage: idLanguage)));
    return translationAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(HymnStrings.loadError,
            style: LumText.body.copyWith(color: c.textSecondary)),
      ),
      data: (translation) {
        if (translation == null) {
          return _PaneMessage(
            message:
                HymnStrings.notAvailable(HymnStrings.languageName(language)),
            actionLabel: HymnStrings.pickAnother,
            onAction: onChange,
          );
        }
        return HymnView(
          translation: translation,
          textScale: textScale,
          onShare: onShare,
          languageLabel: HymnStrings.languageName(language),
          bottomExtraSpace: LumSpace.lg,
          compact: true,
          trailingHeader: Align(
            alignment: Alignment.centerRight,
            child: Semantics(
              button: true,
              label: HymnStrings.change,
              excludeSemantics: true,
              onTap: onChange,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onChange,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                      minHeight: LumSize.touchTarget,
                      minWidth: LumSize.touchTarget),
                  child: Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: LumSpace.md),
                      child: Text(HymnStrings.change,
                          style: LumText.footnoteEmphasized
                              .copyWith(color: c.textAccent)),
                    ),
                  ),
                ),
              ),
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
    final c = context.lum;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(LumSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message,
                textAlign: TextAlign.center,
                style: LumText.body.copyWith(color: c.textSecondary)),
            const SizedBox(height: LumSpace.md),
            Semantics(
              button: true,
              label: actionLabel,
              excludeSemantics: true,
              onTap: onAction,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onAction,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                      minHeight: LumSize.touchTarget,
                      minWidth: LumSize.touchTarget),
                  child: Center(
                    child: Text(actionLabel,
                        style: LumText.subheadlineEmphasized
                            .copyWith(color: c.textAccent)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
