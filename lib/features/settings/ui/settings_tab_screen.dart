import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:openbaptisthymnal/core/audio/audio_quality.dart';
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
import 'package:openbaptisthymnal/features/settings/providers/reading_reminder_provider.dart';
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
            if (!kIsWeb) ...[
              const YouSectionLabel(YouStrings.reminders),
              YouGroup(children: [
                YouControlRow(
                  icon: PhosphorIcons.bell(),
                  title: YouStrings.dailyReminder,
                  child: const _ReadingReminderControl(),
                ),
              ]),
            ],
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
                        style: LumText.footnote
                            .copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
            ]),
            const YouSectionLabel(YouStrings.about),
            YouGroup(children: [
              YouRow(icon: PhosphorIcons.info(), title: version),
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

/// Off by default. Picking a time is the moment permission is asked.
class _ReadingReminderControl extends ConsumerWidget {
  const _ReadingReminderControl();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minutes = ref.watch(readingReminderProvider);
    final notifier = ref.read(readingReminderProvider.notifier);
    final on = minutes != null;
    return Wrap(
      spacing: LumSpace.sm,
      runSpacing: LumSpace.sm,
      children: [
        LumChip(
          label: YouStrings.reminderOff,
          selected: !on,
          onTap: notifier.disable,
        ),
        LumChip(
          label: on
              ? TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60)
                  .format(context)
              : YouStrings.reminderPickTime,
          icon: PhosphorIcons.clock(),
          selected: on,
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: on
                  ? TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60)
                  : const TimeOfDay(hour: 8, minute: 0),
            );
            if (picked == null) return;
            final ok = await notifier.enable(picked.hour, picked.minute);
            if (!ok && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(YouStrings.reminderDenied)));
            }
          },
        ),
      ],
    );
  }
}

/// Default Bible edition `[[bible:...]]` links open in when the link does not
/// pin one. "Follow my reading" (null) opens whatever the reader is on.
class _BibleLinkRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(linkingPreferencesProvider).defaultBibleEditionId;
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
            for (final e in editions)
              YouChoice(id: e.id, label: e.displayName),
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
