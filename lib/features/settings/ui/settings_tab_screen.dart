import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/audio/audio_quality.dart';
import 'package:openbaptisthymnal/core/audio/audio_quality_provider.dart';
import 'package:openbaptisthymnal/core/preferences/linking_preferences.dart';
import 'package:openbaptisthymnal/core/providers/app_info_provider.dart';
import 'package:openbaptisthymnal/core/providers/service_providers.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/theme/app_colors.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/core/theme/theme_provider.dart';
import 'package:openbaptisthymnal/core/utils/toast_helper.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_edition.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';
import 'package:openbaptisthymnal/features/settings/ui/widgets/font_size_control.dart';

/// Settings tab screen - App settings and preferences
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
    final currentTheme = ref.watch(themeModeProvider);

    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Text(
              'Settings',
              style: AppTextStyles.headlineLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // Settings list
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _SettingsSection(
                title: 'Appearance',
                children: [
                  _ThemeSelector(
                    currentTheme: currentTheme,
                    onThemeChanged: (theme) {
                      ref.read(themeModeProvider.notifier).setThemeMode(theme);
                    },
                  ),
                  const _FontSizeSelector(),
                ],
              ),
              const SizedBox(height: 24),
              const _SettingsSection(
                title: 'Linking',
                children: [
                  _DefaultBibleLinkEditionTile(),
                  _DefaultHymnLinkEditionTile(),
                ],
              ),
              const SizedBox(height: 24),
              const _SettingsSection(
                title: 'Voice Notes',
                children: [
                  _AudioQualitySelector(),
                ],
              ),
              const SizedBox(height: 24),
              _SettingsSection(
                title: 'General',
                children: [
                  _SettingsTile(
                    icon: Icons.language_outlined,
                    title: 'Default Language',
                    subtitle: 'English',
                    onTap: () {
                      ToastHelper.info(
                          context, 'Language picker will be available soon');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SettingsSection(
                title: 'About',
                children: [
                  _SettingsTile(
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle: ref.watch(appVersionProvider).when(
                          data: (version) => 'Version $version',
                          loading: () => 'Loading...',
                          error: (_, __) => 'Version Unknown',
                        ),
                    onTap: () {
                      ToastHelper.info(
                          context, 'About dialog will be available soon');
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.menu_book_outlined,
                    title: 'Bible translations',
                    subtitle: 'Sources & licenses',
                    onTap: () => context.router.push(const BibleCreditsRoute()),
                  ),
                  _SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () {
                      ref.read(urlLauncherServiceProvider).openUrl(
                          'https://abide-app-open.vercel.app/privacy.html');
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    onTap: () {
                      ref.read(urlLauncherServiceProvider).openUrl(
                          'https://abide-app-open.vercel.app/terms.html');
                    },
                  ),
                ],
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

/// Settings row surface. Same shape as before — only the light-mode fill is
/// warmed from cool gray to the cream used by the Songs cards so the page reads
/// as the same world. Dark mode keeps its existing surface tone.
BoxDecoration _settingsCardDecoration(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    color:
        isDark ? Theme.of(context).colorScheme.surface : AppColors.secondary100,
    borderRadius: BorderRadius.circular(16),
  );
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // Only the light-mode group fill changes: cool gray -> warm cream wash.
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : AppColors.secondary200,
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8, top: 4),
            child: Text(
              title,
              style: AppTextStyles.labelLarge.copyWith(
                // color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Column(
            spacing: 4,
            children: children,
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: _settingsCardDecoration(context),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Icon(
          icon,
          color: colorScheme.onSurface,
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        trailing: Icon(
          Icons.chevron_right,
          color: colorScheme.outline,
        ),
        onTap: onTap,
      ),
    );
  }
}

/// Font-size selector card: a snapping slider with a live lyric preview.
class _FontSizeSelector extends StatelessWidget {
  const _FontSizeSelector();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: _settingsCardDecoration(context),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.text_fields,
                color: colorScheme.onSurface,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Font Size',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const FontSizeControl(),
        ],
      ),
    );
  }
}

/// Voice-note recording-quality selector: a segmented button plus a line
/// explaining the quality/file-size trade-off for the current choice.
class _AudioQualitySelector extends ConsumerWidget {
  const _AudioQualitySelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final quality = ref.watch(audioQualityProvider);

    return Container(
      decoration: _settingsCardDecoration(context),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.mic_none,
                color: colorScheme.onSurface,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Recording Quality',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<AudioQuality>(
              segments: [
                for (final q in AudioQuality.values)
                  ButtonSegment<AudioQuality>(
                    value: q,
                    label: Text(q.label),
                  ),
              ],
              selected: {quality},
              onSelectionChanged: (selection) {
                ref
                    .read(audioQualityProvider.notifier)
                    .setQuality(selection.first);
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return colorScheme.primary;
                  }
                  return colorScheme.surfaceContainerHighest;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return colorScheme.onPrimary;
                  }
                  return colorScheme.onSurface;
                }),
                side: WidgetStateProperty.all(
                  BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            // Higher quality means clearer audio but larger files; spell out the
            // trade-off so the choice is informed.
            'Higher quality sounds clearer but uses more storage. '
            '${quality.sizeHint}.',
            style: AppTextStyles.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Picker for the default Bible edition `[[bible:...]]` links open in when
/// the link itself doesn't pin one. "Follow my reading" (null) lets tablets
/// stay neutral, so the link opens whatever the user is currently reading.
class _DefaultBibleLinkEditionTile extends ConsumerWidget {
  const _DefaultBibleLinkEditionTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(linkingPreferencesProvider);
    final editions = ref.watch(bibleEditionsProvider);
    final selected = prefs.defaultBibleEditionId;
    final subtitle = _editionLabel(editions, selected);

    return _SettingsTile(
      icon: Icons.menu_book_outlined,
      title: 'Default Bible for links',
      subtitle: subtitle,
      onTap: () async {
        final picked = await _showEditionPicker(
          context,
          title: 'Default Bible for links',
          editions: editions,
          selected: selected,
        );
        if (picked == null) return;
        await ref
            .read(linkingPreferencesProvider.notifier)
            .setDefaultBibleEdition(picked.editionId);
      },
    );
  }

  String _editionLabel(List<BibleEdition> editions, String? id) {
    if (id == null) return 'Follow my reading';
    for (final e in editions) {
      if (e.id == id) return e.displayName;
    }
    return id;
  }
}

/// Picker for the default hymn edition `[[hymn:...]]` links open in. Today an
/// "edition" is a language pack; the future hymnal axis (Baptist, Methodist,
/// CCC, etc.) will slot into the same setting without changing tablets.
class _DefaultHymnLinkEditionTile extends ConsumerWidget {
  const _DefaultHymnLinkEditionTile();

  // Mirror the resolver's installed list. Move to a provider once hymnal ids
  // land in the model.
  static const _options = <({String id, String label})>[
    (id: 'en', label: 'English'),
    (id: 'yo', label: 'Yorùbá'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(linkingPreferencesProvider);
    final selected = prefs.defaultHymnEditionId;
    final subtitle = selected == null
        ? 'Follow my reading'
        : (_options.firstWhere(
            (o) => o.id == selected,
            orElse: () => (id: selected, label: selected),
          )).label;

    return _SettingsTile(
      icon: Icons.music_note_outlined,
      title: 'Default hymnal for links',
      subtitle: subtitle,
      onTap: () async {
        final picked = await showModalBottomSheet<_LinkEditionChoice>(
          context: context,
          showDragHandle: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => _LinkEditionPickerSheet(
            title: 'Default hymnal for links',
            options: [
              const _LinkEditionChoice(
                  editionId: null, label: 'Follow my reading'),
              for (final o in _options)
                _LinkEditionChoice(editionId: o.id, label: o.label),
            ],
            selected: selected,
          ),
        );
        if (picked == null) return;
        await ref
            .read(linkingPreferencesProvider.notifier)
            .setDefaultHymnEdition(picked.editionId);
      },
    );
  }
}

class _LinkEditionChoice {
  const _LinkEditionChoice({required this.editionId, required this.label});

  final String? editionId;
  final String label;
}

Future<_LinkEditionChoice?> _showEditionPicker(
  BuildContext context, {
  required String title,
  required List<BibleEdition> editions,
  required String? selected,
}) {
  return showModalBottomSheet<_LinkEditionChoice>(
    context: context,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _LinkEditionPickerSheet(
      title: title,
      options: [
        const _LinkEditionChoice(editionId: null, label: 'Follow my reading'),
        for (final e in editions)
          _LinkEditionChoice(editionId: e.id, label: e.displayName),
      ],
      selected: selected,
    ),
  );
}

class _LinkEditionPickerSheet extends StatelessWidget {
  const _LinkEditionPickerSheet({
    required this.title,
    required this.options,
    required this.selected,
  });

  final String title;
  final List<_LinkEditionChoice> options;
  final String? selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Text(
                title,
                style: AppTextStyles.titleMedium
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final option in options)
                      // ignore: deprecated_member_use
                      RadioListTile<String?>(
                        value: option.editionId,
                        // ignore: deprecated_member_use
                        groupValue: selected,
                        title: Text(option.label),
                        activeColor: colorScheme.primary,
                        // ignore: deprecated_member_use
                        onChanged: (_) => Navigator.of(context).pop(option),
                      ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

/// Theme selector with segmented button for Light, Dark, System
class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({
    required this.currentTheme,
    required this.onThemeChanged,
  });

  final ThemeMode currentTheme;
  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: _settingsCardDecoration(context),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette_outlined,
                color: colorScheme.onSurface,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Theme',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto_outlined),
                ),
              ],
              selected: {currentTheme},
              onSelectionChanged: (Set<ThemeMode> selection) {
                onThemeChanged(selection.first);
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return colorScheme.primary;
                  }
                  return colorScheme.surfaceContainerHighest;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return colorScheme.onPrimary;
                  }
                  return colorScheme.onSurface;
                }),
                side: WidgetStateProperty.all(
                  BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
