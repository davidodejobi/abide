import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/features/tablet/domain/parse_links.dart';

final _wikilink = RegExp(r'\[\[[^\[\]]*\]\]');

/// Empty when [raw] has no link. Splits [raw] into plain spans and gold, underlined, tappable `[[...]]`
/// spans. Shared by the editor's text decorator and media captions so links
/// behave the same everywhere. Recognizers created are added to [recognizers]
/// when given, so a stateful caller can dispose them.
List<InlineSpan> wikilinkSpans(
  BuildContext context,
  String raw,
  TextStyle? baseStyle,
  void Function(ParsedLink link)? onTap, {
  List<TapGestureRecognizer>? recognizers,
}) {
  final matches = _wikilink.allMatches(raw).toList();
  if (matches.isEmpty) return const [];
  final children = <InlineSpan>[];
  var cursor = 0;
  for (final m in matches) {
    if (m.start > cursor) {
      children.add(
        TextSpan(text: raw.substring(cursor, m.start), style: baseStyle),
      );
    }
    final token = raw.substring(m.start, m.end);
    final parsed = parseLinks(token);
    TapGestureRecognizer? recognizer;
    if (parsed.isNotEmpty && onTap != null) {
      recognizer = TapGestureRecognizer()..onTap = () => onTap(parsed.first);
      recognizers?.add(recognizer);
    }
    children.add(TextSpan(
      text: token,
      style: (baseStyle ?? const TextStyle()).copyWith(
        color: context.lum.textAccent,
        decoration: TextDecoration.underline,
        decorationColor: context.lum.textAccent,
      ),
      recognizer: recognizer,
    ));
    cursor = m.end;
  }
  if (cursor < raw.length) {
    children.add(TextSpan(text: raw.substring(cursor), style: baseStyle));
  }
  return children;
}
