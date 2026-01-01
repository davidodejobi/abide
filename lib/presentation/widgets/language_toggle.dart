import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../utils/theme/theme.dart';

class LanguageToggle extends HookWidget {
  final String selectedLanguage;
  final ValueChanged<String> onLanguageChanged;

  const LanguageToggle({
    super.key,
    required this.selectedLanguage,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final initialIndex = selectedLanguage == 'yo' ? 0 : 1;
    final tabController = useTabController(
      initialLength: 2,
      initialIndex: initialIndex,
    );

    // Sync tab controller with external state
    useEffect(() {
      final newIndex = selectedLanguage == 'yo' ? 0 : 1;
      if (tabController.index != newIndex) {
        tabController.animateTo(newIndex);
      }
      return null;
    }, [selectedLanguage]);

    // Handle tab changes
    useEffect(() {
      void listener() {
        if (!tabController.indexIsChanging) {
          final language = tabController.index == 0 ? 'yo' : 'en';
          if (language != selectedLanguage) {
            onLanguageChanged(language);
          }
        }
      }

      tabController.addListener(listener);
      return () => tabController.removeListener(listener);
    }, [tabController, selectedLanguage, onLanguageChanged]);

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.surfaceContainerHighest,
      ),
      child: TabBar(
        controller: tabController,
        labelColor: colorScheme.onPrimary,
        unselectedLabelColor: colorScheme.onSurface,
        indicatorWeight: 0,
        enableFeedback: true,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: colorScheme.primary,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        labelStyle: AppTextStyles.labelLarge.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.labelLarge.copyWith(
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Yoruba Version'),
          Tab(text: 'English Version'),
        ],
      ),
    );
  }
}
