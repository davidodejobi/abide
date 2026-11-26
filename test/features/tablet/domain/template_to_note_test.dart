import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/tablet/domain/builtin_templates.dart';
import 'package:openbaptisthymnal/features/tablet/domain/note_template.dart';
import 'package:openbaptisthymnal/features/tablet/domain/parse_links.dart';
import 'package:openbaptisthymnal/features/tablet/domain/tablet_markdown_codec.dart';
import 'package:openbaptisthymnal/features/tablet/domain/template_to_note.dart';

void main() {
  final now = DateTime(2026, 11, 26);

  group('Given the built-in templates', () {
    test('Then there are five, with the one shared Sermon', () {
      expect(builtInTemplates.map((t) => t.name), [
        'Sermon',
        'Prayer journal',
        'Bible study',
        'Small group',
        'Devotional',
      ]);
      expect(builtInTemplates.every((t) => t.builtIn), isTrue);
      expect(builtInTemplates.first, same(sermonTemplate));
      expect(builtInTemplateById('builtin:sermon'), same(sermonTemplate));
    });

    test('Then Sermon has the agreed fields and sections, no typo, no title',
        () {
      final labels = sermonTemplate.sections.map((s) => s.label).toList();
      expect(labels, [
        'Speaker', 'Place', 'Date', 'Passage', //
        'Main points', 'Passages referenced', 'Application', 'Prayer',
      ]);
      final copy = sermonTemplate.sections.map((s) => s.hint).join(' ') +
          sermonTemplate.summary;
      expect(copy, isNot(contains('this this')));
      expect(copy.toLowerCase(), isNot(contains('pastor')));
      expect(copy, isNot(contains('—')));
    });
  });

  group('Given a template turned into markdown', () {
    test('Then Sermon is fields first, then headed sections', () {
      final md = templateToMarkdown(sermonTemplate,
          now: now, lastSpeaker: 'Daniel Okafor');
      expect(md, contains('**Speaker:** Daniel Okafor'));
      expect(md, contains('**Place:**'));
      expect(md, contains('**Date:** 26 Nov 2026'));
      expect(md, contains('**Passage:**'));
      expect(md, contains('## Main points'));
      expect(md, contains('## Passages referenced'));
      expect(md, contains('## Application'));
      expect(md, contains('## Prayer'));
      // Hints are placeholders only: none of them is in the note.
      expect(md, isNot(contains('The first big idea')));
      expect(md, isNot(contains('What will you do this week')));
    });

    test('Then bullets and checklists get their empty marker', () {
      const t = NoteTemplate(id: 'x', name: 'X', icon: 'book', sections: [
        TemplateSection(TemplateSectionType.bullet, 'Points'),
        TemplateSection(TemplateSectionType.checklist, 'To do'),
        TemplateSection(TemplateSectionType.heading, 'Divider'),
      ]);
      final md = templateToMarkdown(t, now: now);
      expect(md, contains('## Points\n\n* '));
      expect(md, contains('## To do\n\n- [ ]'));
      expect(md, contains('## Divider'));
    });

    test('Then Speaker is blank without a last speaker', () {
      final md = templateToMarkdown(sermonTemplate, now: now);
      expect(md, contains('**Speaker:**'));
      expect(md, isNot(contains('Daniel')));
    });

    test('Then fields parse as plain lines and add no links', () {
      final md = templateToMarkdown(sermonTemplate, now: now);
      expect(parseLinks(md), isEmpty);
    });

    test('Then a filled passage token is indexed as a link', () {
      final md = '${templateToMarkdown(sermonTemplate, now: now).trimRight()}'
          ' [[bible:JHN.15.1-8]]';
      expect(parseLinks(md).single.targetKey, 'JHN.15.1-8');
    });
  });

  group('Given hints', () {
    test('Then an empty block takes the hint of the heading above it', () {
      final doc = templateToDocument(sermonTemplate, now: now);
      final hints = templateHints(sermonTemplate);
      final nodes = doc.root.children.toList();
      final bullet =
          nodes.firstWhere((n) => n.type == BulletedListBlockKeys.type);
      expect(hintFor(bullet, hints), 'The first big idea, in your own words');
      final application = nodes.lastWhere((n) =>
          n.type == ParagraphBlockKeys.type && n.previous?.delta != null &&
          n.previous!.delta!.toPlainText() == 'Application');
      expect(hintFor(application, hints), 'What will you do this week?');
    });

    test('Then a node with no heading above has no hint', () {
      final doc = templateToDocument(sermonTemplate, now: now);
      expect(hintFor(doc.root.children.first, templateHints(sermonTemplate)),
          '');
    });
  });

  group('Given the speaker memory', () {
    test('Then the Speaker line is read back, blank ones are not', () {
      expect(lastSpeakerFrom('**Speaker:** Daniel Okafor\n\n**Place:** x'),
          'Daniel Okafor');
      expect(lastSpeakerFrom('**Speaker:** \n\n**Place:** x'), isNull);
      expect(lastSpeakerFrom('nothing here'), isNull);
    });
  });

  group('Given a note saved as a template', () {
    test('Then headings absorb the block below and fields become fields', () {
      final doc = noteMarkdownToDocument(
        '**Speaker:** Ada\n\n**Passage:** [[bible:JHN.3.16]]\n\n'
        '## Main points\n\n- first\n\n## Application\n\nDo it\n\n'
        '## Follow-up\n\n- [ ] call\n\n## Divider\n\n![](note_images/x.png)',
      );
      final sections = documentToSections(doc);
      expect(sections, const [
        TemplateSection(TemplateSectionType.field, 'Speaker'),
        TemplateSection(TemplateSectionType.scripture, 'Passage'),
        TemplateSection(TemplateSectionType.bullet, 'Main points',
            hint: 'first'),
        TemplateSection(TemplateSectionType.text, 'Application',
            hint: 'Do it'),
        TemplateSection(TemplateSectionType.checklist, 'Follow-up',
            hint: 'call'),
        TemplateSection(TemplateSectionType.heading, 'Divider'),
      ]);
    });

    test('Then the Sermon template survives its own round trip', () {
      final doc = noteMarkdownToDocument(
          templateToMarkdown(sermonTemplate, now: now, lastSpeaker: 'Ada'));
      final sections = documentToSections(doc);
      expect(sections.map((s) => (s.type, s.label)).toList(), [
        (TemplateSectionType.field, 'Speaker'),
        (TemplateSectionType.field, 'Place'),
        (TemplateSectionType.field, 'Date'),
        (TemplateSectionType.scripture, 'Passage'),
        (TemplateSectionType.bullet, 'Main points'),
        (TemplateSectionType.heading, 'Passages referenced'),
        (TemplateSectionType.heading, 'Application'),
        (TemplateSectionType.heading, 'Prayer'),
      ]);
    });
  });

  group('Given Save as template from an untouched template note', () {
    test('Then the original hints and section types come back', () {
      final doc = noteMarkdownToDocument(
          templateToMarkdown(sermonTemplate, now: now));
      final sections = restoreTemplateHints(
          documentToSections(doc), sermonTemplate);
      final application =
          sections.firstWhere((s) => s.label == 'Application');
      expect(application.type, TemplateSectionType.text);
      expect(application.hint, 'What will you do this week?');
      final points = sections.firstWhere((s) => s.label == 'Main points');
      expect(points.type, TemplateSectionType.bullet);
      expect(points.hint, 'The first big idea, in your own words');
    });

    test('Then text the user typed is kept as the hint', () {
      final restored = restoreTemplateHints(const [
        TemplateSection(TemplateSectionType.text, 'Application',
            hint: 'My own words'),
      ], sermonTemplate);
      expect(restored.single.hint, 'My own words');
    });
  });

  group('Given stored sections', () {
    test('Then JSON round-trips and a bad row decodes to nothing', () {
      final json = encodeSections(sermonTemplate.sections);
      expect(decodeSections(json), sermonTemplate.sections);
      expect(decodeSections('not json'), isEmpty);
      expect(decodeSections('{"a":1}'), isEmpty);
      expect(decodeSections('[{"type":"nope","label":"x"}]'), isEmpty);
    });
  });
}
