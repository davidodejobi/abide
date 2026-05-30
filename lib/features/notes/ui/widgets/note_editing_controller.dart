import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/app_colors.dart';
import 'package:openbaptisthymnal/features/notes/domain/markdown_spans.dart';

/// A [TextEditingController] that renders note markdown with live inline
/// styling: `[[links]]` become gold underlined text, `**bold**`, `*italic*`,
/// and `# headings` are styled in place. The markdown markers stay in the text
/// so it remains the single source of truth.
///
/// Tap-to-navigate is handled by the host widget via the field's `onTap`
/// (see `NoteEditorPage`) — gesture recognizers cannot be attached to spans in
/// an editable field, which asserts `readOnly && !obscureText`.
class NoteEditingController extends TextEditingController {
  NoteEditingController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = style ?? const TextStyle();
    final runs = computeMarkdownRuns(text);
    if (runs.isEmpty) {
      return TextSpan(text: text, style: base);
    }

    final spans = <InlineSpan>[];
    for (final run in runs) {
      final slice = text.substring(run.start, run.end);
      switch (run.type) {
        case MarkdownRunType.plain:
          spans.add(TextSpan(text: slice, style: base));
        case MarkdownRunType.bold:
          spans.add(TextSpan(
            text: slice,
            style: base.copyWith(fontWeight: FontWeight.w700),
          ));
        case MarkdownRunType.italic:
          spans.add(TextSpan(
            text: slice,
            style: base.copyWith(fontStyle: FontStyle.italic),
          ));
        case MarkdownRunType.heading:
          spans.add(TextSpan(
            text: slice,
            style: base.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: (base.fontSize ?? 18) * 1.25,
              height: 1.3,
            ),
          ));
        case MarkdownRunType.link:
          spans.add(TextSpan(
            text: slice,
            style: base.copyWith(
              color: AppColors.secondary,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.secondary,
            ),
          ));
      }
    }
    return TextSpan(style: base, children: spans);
  }
}
