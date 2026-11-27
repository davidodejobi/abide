import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:openbaptisthymnal/core/audio/audio_quality.dart';
import 'package:openbaptisthymnal/features/account/providers/account_providers.dart';
import 'package:openbaptisthymnal/features/account/ui/account_strings.dart';
import 'package:openbaptisthymnal/features/account/ui/save_road_sheet.dart';
import 'package:openbaptisthymnal/core/audio/audio_quality_provider.dart';
import 'package:openbaptisthymnal/core/preferences/linking_preferences.dart';
import 'package:openbaptisthymnal/core/providers/app_info_provider.dart';
import 'package:openbaptisthymnal/core/providers/service_providers.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/theme/theme_provider.dart';
import 'package:openbaptisthymnal/core/widgets/lum_chip.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_edition.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';
import 'package:openbaptisthymnal/features/daily/providers/landmark_download_provider.dart';
import 'package:openbaptisthymnal/features/plus/plus_config.dart';
import 'package:openbaptisthymnal/features/plus/providers/plus_providers.dart';
import 'package:openbaptisthymnal/features/plus/ui/plus_gate.dart';
import 'package:openbaptisthymnal/features/plus/ui/trial_reminder_card.dart';
import 'package:openbaptisthymnal/features/settings/ui/widgets/font_size_control.dart';
import 'package:openbaptisthymnal/features/settings/ui/widgets/you_rows.dart';
import 'package:openbaptisthymnal/features/settings/ui/you_strings.dart';

/// The You tab (Figma M2 "You"): appearance, link defaults, voice-note quality
/// and About. Same providers as the old Settings screen; only the surface is
/// new. The class keeps its name so the generated route stays put.
@RoutePage()
class SettingsTabScreen extends ConsumerStatefulWidget {
  const SettingsTabScreen({super.key});

  @override
  ConsumerState<SettingsTabScreen> createState() => _SettingsTabScreenState();
}

class _SettingsTabScreenState extends ConsumerState<SettingsTabScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = context.lum;
    final theme = ref.watch(themeModeProvider);
    final quality = ref.watch(audioQualityProvider);
    final version = ref.watch(appVersionProvider).when(
          data: YouStrings.versionLabel,
          loading: () => YouStrings.versionLoading,
          error: (_, __) => YouStrings.versionUnknown,
        );

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          // Bottom clears the floating tab bar.
          padding: const EdgeInsets.fromLTRB(
              LumSize.screenGutter, LumSpace.lg, LumSize.screenGutter, 120),
          children: [
            Semantics(
              header: true,
              child: Text(YouStrings.title,
                  style: LumText.largeTitle.copyWith(color: c.textPrimary)),
            ),
            if (ref.watch(plusEnabledProvider)) ...[
              const SizedBox(height: LumSpace.lg),
              const TrialReminderCard(),
              YouGroup(children: [
                YouRow(
                  icon: PhosphorIcons.sparkle(),
                  title: PlusStrings.plusRow,
                  subtitle: ref.watch(plusProvider.select((e) => e.isPlus))
                      ? PlusStrings.plusRowActive
                      : PlusStrings.plusRowFree,
                  onTap: () => context.router.push(const PlusRoute()),
                ),
                YouRow(
                  icon: PhosphorIcons.heart(),
                  title: PlusStrings.sponsorRow,
                  onTap: () => context.router.push(const SponsorRoute()),
                ),
                // Example Plus gate, debug only until a real Plus feature exists.
                if (kDebugMode)
                  YouRow(
                    icon: PhosphorIcons.cloudArrowUp(),
                    title: PlusFeature.sync.title,
                    onTap: () => requirePlus(context, ref, PlusFeature.sync),
                  ),
                if (kDebugMode)
                  Material(
                    type: MaterialType.transparency,
                    child: SwitchListTile(
                      title: const Text(PlusStrings.debugToggle),
                      value: ref.watch(plusProvider.select((e) => e.isPlus)),
                      onChanged: (v) =>
                          ref.read(plusProvider.notifier).debugSet(v),
                    ),
                  ),
              ]),
            ],
            if (ref.watch(authRepositoryProvider) != null) ...[
              const YouSectionLabel(AccountStrings.youSection),
              YouGroup(children: _accountRows(context, ref)),
            ],
            const YouSectionLabel(YouStrings.appearance),
            YouGroup(children: [
              YouControlRow(
                icon: PhosphorIcons.palette(),
                title: YouStrings.theme,
                child: Wrap(
                  spacing: LumSpace.sm,
                  runSpacing: LumSpace.sm,
                  children: [
                    for (final (mode, label, icon) in [
                      (ThemeMode.light, YouStrings.light, PhosphorIcons.sun()),
                      (ThemeMode.dark, YouStrings.dark, PhosphorIcons.moon()),
                      (
                        ThemeMode.system,
                        YouStrings.system,
                        PhosphorIcons.circleHalf()
                      ),
                    ])
                      LumChip(
                        label: label,
                        icon: icon,
                        selected: theme == mode,
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(mode),
                      ),
                  ],
                ),
              ),
              YouControlRow(
                icon: PhosphorIcons.textAa(),
                title: YouStrings.fontSize,
                child: const FontSizeControl(),
              ),
            ]),
            const YouSectionLabel(YouStrings.linking),
            YouGroup(children: [
              _BibleLinkRow(),
              _HymnLinkRow(),
            ]),
            const YouSectionLabel(YouStrings.notes),
            YouGroup(children: [
              YouRow(
                icon: PhosphorIcons.notebook(),
                title: YouStrings.manageTemplates,
                subtitle: YouStrings.manageTemplatesHint,
                onTap: () => context.router.push(const ManageTemplatesRoute()),
              ),
            ]),
            const YouSectionLabel(YouStrings.voiceNotes),
            YouGroup(children: [
              YouControlRow(
                icon: PhosphorIcons.microphone(),
                title: YouStrings.recordingQuality,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: LumSpace.sm,
                      runSpacing: LumSpace.sm,
                      children: [
                        for (final q in AudioQuality.values)
                          LumChip(
                            label: q.label,
                            selected: q == quality,
                            onTap: () => ref
                                .read(audioQualityProvider.notifier)
                                .setQuality(q),
                          ),
                      ],
                    ),
                    const SizedBox(height: LumSpace.md),
                    Text(YouStrings.qualityHint(quality.sizeHint),
                        style:
                            LumText.footnote.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
            ]),
            if (ref.read(landmarkDownloadProvider.notifier).supported) ...[
              const YouSectionLabel(YouStrings.road),
              const YouGroup(children: [RoadLandmarksRow()]),
            ],
            const YouSectionLabel(YouStrings.about),
            YouGroup(children: [
              YouRow(icon: PhosphorIcons.info(), title: version),
              if (!kIsWeb)
                YouRow(
                  icon: PhosphorIcons.downloadSimple(),
                  title: YouStrings.getMoreBibles,
                  subtitle: YouStrings.getMoreBiblesHint,
                  onTap: () => context.router.push(const MoreBiblesRoute()),
                ),
              YouRow(
                icon: PhosphorIcons.bookOpenText(),
                title: YouStrings.bibleTranslations,
                subtitle: YouStrings.sourcesLicenses,
                onTap: () => context.router.push(const BibleCreditsRoute()),
              ),
              YouRow(
                icon: PhosphorIcons.shieldCheck(),
                title: YouStrings.privacy,
                onTap: () => ref
                    .read(urlLauncherServiceProvider)
                    .openUrl(YouStrings.privacyUrl),
              ),
              YouRow(
                icon: PhosphorIcons.fileText(),
                title: YouStrings.terms,
                onTap: () => ref
                    .read(urlLauncherServiceProvider)
                    .openUrl(YouStrings.termsUrl),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

/// Default Bible edition `[[bible:...]]` links open in when the link does not
/// pin one. "Follow my reading" (null) opens whatever the reader is on.
class _BibleLinkRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected =
        ref.watch(linkingPreferencesProvider).defaultBibleEditionId;
    final editions = ref.watch(bibleEditionsProvider);

    return YouRow(
      icon: PhosphorIcons.bookOpenText(),
      title: YouStrings.linkBible,
      subtitle: _label(editions, selected),
      onTap: () async {
        final picked = await showYouPicker(
          context,
          title: YouStrings.linkBible,
          selected: selected,
          options: [
            const YouChoice(id: null, label: YouStrings.followReading),
            for (final e in editions) YouChoice(id: e.id, label: e.displayName),
          ],
        );
        if (picked == null) return;
        await ref
            .read(linkingPreferencesProvider.notifier)
            .setDefaultBibleEdition(picked.id);
      },
    );
  }

  String _label(List<BibleEdition> editions, String? id) {
    if (id == null) return YouStrings.followReading;
    for (final e in editions) {
      if (e.id == id) return e.displayName;
    }
    return id;
  }
}

/// Default hymn edition `[[hymn:...]]` links open in. Today an edition is a
/// language pack.
class _HymnLinkRow extends ConsumerWidget {
  // Mirror the resolver's installed list.
  static const _options = <YouChoice>[
    YouChoice(id: 'en', label: YouStrings.english),
    YouChoice(id: 'yo', label: YouStrings.yoruba),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(linkingPreferencesProvider).defaultHymnEditionId;
    final label = selected == null
        ? YouStrings.followReading
        : _options
            .firstWhere((o) => o.id == selected,
                orElse: () => YouChoice(id: selected, label: selected))
            .label;

    return YouRow(
      icon: PhosphorIcons.musicNote(),
      title: YouStrings.linkHymnal,
      subtitle: label,
      onTap: () async {
        final picked = await showYouPicker(
          context,
          title: YouStrings.linkHymnal,
          selected: selected,
          options: const [
            YouChoice(id: null, label: YouStrings.followReading),
            ..._options,
          ],
        );
        if (picked == null) return;
        await ref
            .read(linkingPreferencesProvider.notifier)
            .setDefaultHymnEdition(picked.id);
      },
    );
  }
}

/// Status of the 3D road landmarks; opens the "Your road ahead" page.
class RoadLandmarksRow extends ConsumerStatefulWidget {
  const RoadLandmarksRow({super.key});

  @override
  ConsumerState<RoadLandmarksRow> createState() => _RoadLandmarksRowState();
}

class _RoadLandmarksRowState extends ConsumerState<RoadLandmarksRow> {
  @override
  void initState() {
    super.initState();
    Future(() => ref.read(landmarkDownloadProvider.notifier).refresh());
  }

  String _status(LandmarkDownloadState s) {
    final size = landmarkSizeLabel(s.totalBytes);
    if (s.totalFiles == 0) return YouStrings.roadNone;
    final base = switch (s.status) {
      LandmarkDownloadStatus.done => YouStrings.roadDownloaded,
      _ when s.doneFiles == 0 => YouStrings.roadNone,
      _ => YouStrings.roadPartial(s.doneFiles, s.totalFiles),
    };
    return YouStrings.roadSizeNote(base, size);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(landmarkDownloadProvider);
    return YouRow(
      icon: PhosphorIcons.mountains(),
      title: YouStrings.roadLandmarks,
      subtitle: _status(s),
      onTap: () => context.router.push(const RoadAheadRoute()),
    );
  }
}

/// "Saved as x@y" once the road is saved, otherwise the way into the sheet.
List<Widget> _accountRows(BuildContext context, WidgetRef ref) {
  final account = ref.watch(accountProvider).valueOrNull;
  if (account == null || !account.isSaved) {
    return [
      YouRow(
        icon: PhosphorIcons.userCirclePlus(),
        title: AccountStrings.saveRow,
        subtitle: AccountStrings.saveRowHint,
        onTap: () => showSaveRoadSheet(context),
      ),
    ];
  }
  return [
    YouRow(
      icon: PhosphorIcons.userCheck(),
      title: AccountStrings.signedInWith(account),
      subtitle: AccountStrings.savedHint,
    ),
    YouRow(
      icon: PhosphorIcons.signOut(),
      title: AccountStrings.signOut,
      onTap: () => _confirmSignOut(context, ref),
    ),
  ];
}

Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text(AccountStrings.signOutTitle),
      content: const Text(AccountStrings.signOutBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text(AccountStrings.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text(AccountStrings.signOut),
        ),
      ],
    ),
  );
  if (ok != true) return;
  var saved = false;
  try {
    saved = await ref.read(signOutProvider.notifier).signOut();
  } catch (_) {
    // Offline or a failed call: nothing was removed, so say the same thing.
  }
  if (!saved && context.mounted) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: const Text(AccountStrings.signOutUnsaved),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AccountStrings.ok),
          ),
        ],
      ),
    );
  }
}
