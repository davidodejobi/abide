import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/app_colors.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';

/// A language option the hymnal can switch between.
class LanguageOption {
  const LanguageOption({required this.code, required this.label});

  /// Language code stored in state (e.g. 'yo', 'en').
  final String code;

  /// Human-friendly chip label (e.g. 'Yoruba').
  final String label;
}

/// Horizontal, scrollable row of language chips. Renders the languages it is
/// given today and grows gracefully as more are added in future releases —
/// no fixed two-tab assumption.
class LanguageToggle extends StatelessWidget {
  final String selectedLanguage;
  final ValueChanged<String> onLanguageChanged;
  final List<LanguageOption> languages;

  const LanguageToggle({
    super.key,
    required this.selectedLanguage,
    required this.onLanguageChanged,
    this.languages = const [
      LanguageOption(code: 'yo', label: 'Yoruba'),
      LanguageOption(code: 'en', label: 'English'),
    ],
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: languages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final language = languages[index];
          return _LanguageChip(
            label: language.label,
            selected: language.code == selectedLanguage,
            onTap: () => onLanguageChanged(language.code),
          );
        },
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fill = selected
        ? AppColors.secondary
        : (isDark ? AppColors.neutral800 : AppColors.secondary50);
    final textColor = selected
        ? AppColors.primaryDark
        : (isDark ? AppColors.neutral300 : AppColors.primary);
    final border = selected
        ? AppColors.secondary
        : (isDark ? AppColors.neutral700 : AppColors.secondary200);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border, width: 1),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(
              color: textColor,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
