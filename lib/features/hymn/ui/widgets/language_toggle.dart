import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/widgets/lum_chip.dart';
import 'package:openbaptisthymnal/features/hymn/ui/hymn_strings.dart';

/// A language option the hymnal can switch between.
class LanguageOption {
  const LanguageOption({required this.code, required this.label});

  /// Language code stored in state (e.g. 'yo', 'en').
  final String code;

  /// Human-friendly chip label (e.g. 'Yorùbá').
  final String label;
}

/// Wrapping row of language chips, plus an optional trailing action chip
/// (Favourites). Renders the languages it is given today and grows as more are
/// added: it wraps instead of overflowing.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({
    super.key,
    required this.selectedLanguage,
    required this.onLanguageChanged,
    this.languages = const [
      LanguageOption(code: 'en', label: HymnStrings.english),
      LanguageOption(code: 'yo', label: HymnStrings.yoruba),
    ],
    this.trailing,
  });

  final String selectedLanguage;
  final ValueChanged<String> onLanguageChanged;
  final List<LanguageOption> languages;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final language in languages)
          LumChip(
            label: language.label,
            selected: language.code == selectedLanguage,
            onTap: () => onLanguageChanged(language.code),
          ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
