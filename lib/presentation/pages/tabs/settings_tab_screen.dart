import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/theme_provider.dart';
import '../../../utils/theme/theme.dart';

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
                      ref.read(themeModeProvider.notifier).state = theme;
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.text_fields,
                    title: 'Font Size',
                    subtitle: 'Medium',
                    onTap: () {
                      // TODO: Show font size picker
                    },
                  ),
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
                      // TODO: Show language picker
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
                    subtitle: 'Version 1.0.0',
                    onTap: () {
                      // TODO: Show about dialog
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () {
                      // TODO: Open privacy policy
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    onTap: () {
                      // TODO: Open terms of service
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surfaceContainerHighest,
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
                color: colorScheme.onSurfaceVariant,
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
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
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
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
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
