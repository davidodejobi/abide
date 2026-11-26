import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:openbaptisthymnal/features/tablet/domain/note_template.dart';
import 'package:openbaptisthymnal/features/tablet/domain/tablet_markdown_codec.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
];

/// "26 Nov 2026": what the Date field is filled with.
String templateDateText(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

Delta _labelDelta(String label, String value) => Delta()
  ..insert('$label:', attributes: {'bold': true})
  ..insert(value.isEmpty ? ' ' : ' $value');

/// Builds the editor document for a new note from [template]. Text, bullet
/// and checklist sections become a `##` heading plus an empty block (empty
/// paragraphs would not survive markdown, which is why the document is built
/// directly rather than parsed). Date is filled with [now]; Speaker with
/// [lastSpeaker] when known.
Document templateToDocument(
  NoteTemplate template, {
  required DateTime now,
  String? lastSpeaker,
}) {
  final nodes = <Node>[];
  for (final s in template.sections) {
    final label = s.label.trim();
    switch (s.type) {
      case TemplateSectionType.heading:
        nodes.add(headingNode(level: 2, text: label));
      case TemplateSectionType.text:
        nodes
          ..add(headingNode(level: 2, text: label))
          ..add(paragraphNode());
      case TemplateSectionType.bullet:
        nodes
          ..add(headingNode(level: 2, text: label))
          ..add(bulletedListNode());
      case TemplateSectionType.checklist:
        nodes
          ..add(headingNode(level: 2, text: label))
          ..add(todoListNode(checked: false));
      case TemplateSectionType.scripture:
        nodes.add(paragraphNode(delta: _labelDelta(label, '')));
      case TemplateSectionType.field:
        final key = label.toLowerCase();
        final value = key == 'date'
            ? templateDateText(now)
            : key == 'speaker'
                ? (lastSpeaker ?? '')
                : '';
        nodes.add(paragraphNode(delta: _labelDelta(label, value)));
    }
  }
  if (nodes.isEmpty) nodes.add(paragraphNode());
  return Document(root: pageNode(children: nodes));
}

/// The markdown a fresh note from [template] holds before the user types.
String templateToMarkdown(
  NoteTemplate template, {
  required DateTime now,
  String? lastSpeaker,
}) =>
    noteDocumentToMarkdown(
        templateToDocument(template, now: now, lastSpeaker: lastSpeaker));

/// Placeholder text per heading label (the hint of the section's body).
Map<String, String> templateHints(NoteTemplate template) => {
      for (final s in template.sections)
        if (s.hint.isNotEmpty &&
            (s.type == TemplateSectionType.text ||
                s.type == TemplateSectionType.bullet ||
                s.type == TemplateSectionType.checklist))
          s.label.trim(): s.hint,
    };

/// The hint for an empty block: the one of the nearest heading above it.
String hintFor(Node node, Map<String, String> hints) {
  if (hints.isEmpty) return '';
  for (Node? n = node.previous; n != null; n = n.previous) {
    if (n.type == HeadingBlockKeys.type) {
      return hints[(n.delta?.toPlainText() ?? '').trim()] ?? '';
    }
  }
  return '';
}

final _speakerLine = RegExp(r'^\*\*Speaker:\*\*[ \t]*(.+)$', multiLine: true);

/// The speaker written in a saved note, to default the next one to.
String? lastSpeakerFrom(String markdown) {
  final v = _speakerLine.firstMatch(markdown)?.group(1)?.trim();
  return v == null || v.isEmpty ? null : v;
}

/// Label of a `**Label:** value` paragraph, else null.
String? _fieldLabel(Node node) {
  final ops = node.delta?.toList();
  if (ops == null || ops.isEmpty) return null;
  final first = ops.first;
  if (first is! TextInsert || first.attributes?['bold'] != true) return null;
  final t = first.text.trim();
  if (!t.endsWith(':') || t.length < 2) return null;
  return t.substring(0, t.length - 1).trim();
}

/// "Save as template": walks a note's document into template sections.
/// Headings absorb the block under them, `**X:**` lines become fields,
/// media and everything else is dropped. A paragraph's own text becomes the
/// hint, never the template's content.
List<TemplateSection> documentToSections(Document document) {
  final out = <TemplateSection>[];
  final nodes = document.root.children.toList();
  for (var i = 0; i < nodes.length; i++) {
    final n = nodes[i];
    final text = (n.delta?.toPlainText() ?? '').trim();
    switch (n.type) {
      case HeadingBlockKeys.type:
        if (text.isEmpty) break;
        final next = i + 1 < nodes.length ? nodes[i + 1] : null;
        final nextText = (next?.delta?.toPlainText() ?? '').trim();
        if (next != null && next.type == BulletedListBlockKeys.type) {
          out.add(TemplateSection(TemplateSectionType.bullet, text,
              hint: nextText));
          i++;
        } else if (next != null && next.type == TodoListBlockKeys.type) {
          out.add(TemplateSection(TemplateSectionType.checklist, text,
              hint: nextText));
          i++;
        } else if (next != null &&
            next.type == ParagraphBlockKeys.type &&
            _fieldLabel(next) == null) {
          out.add(TemplateSection(TemplateSectionType.text, text,
              hint: nextText));
          i++;
        } else {
          out.add(TemplateSection(TemplateSectionType.heading, text));
        }
      case ParagraphBlockKeys.type:
        final label = _fieldLabel(n);
        if (label != null) {
          final isScripture = {'passage', 'scripture', 'verse'}
              .contains(label.toLowerCase());
          out.add(TemplateSection(
            isScripture
                ? TemplateSectionType.scripture
                : TemplateSectionType.field,
            label,
          ));
        } else if (text.isNotEmpty) {
          out.add(TemplateSection(TemplateSectionType.text, 'Notes',
              hint: text));
        }
      case BulletedListBlockKeys.type:
        if (text.isNotEmpty) {
          out.add(TemplateSection(TemplateSectionType.bullet, 'List',
              hint: text));
        }
      case TodoListBlockKeys.type:
        if (text.isNotEmpty) {
          out.add(TemplateSection(TemplateSectionType.checklist, 'Checklist',
              hint: text));
        }
    }
  }
  return out;
}
