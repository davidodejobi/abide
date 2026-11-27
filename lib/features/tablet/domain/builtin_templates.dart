import 'package:openbaptisthymnal/features/tablet/domain/note_template.dart';

const _field = TemplateSectionType.field;
const _scripture = TemplateSectionType.scripture;
const _bullet = TemplateSectionType.bullet;
const _text = TemplateSectionType.text;
const _checklist = TemplateSectionType.checklist;

/// The one Sermon definition, shared by every surface that starts a sermon
/// note (the picker, the recorder).
const sermonTemplate = NoteTemplate(
  id: 'builtin:sermon',
  name: 'Sermon',
  icon: 'church',
  builtIn: true,
  subtitle: 'Speaker · Passage · Points · Application · Pray',
  sections: [
    TemplateSection(_field, 'Speaker', hint: 'Who is speaking'),
    TemplateSection(_field, 'Place', hint: 'Church or venue'),
    TemplateSection(_field, 'Date'),
    TemplateSection(_scripture, 'Passage'),
    // Matches the design (templates_04): three numbered points, then
    // references, application and a prayer.
    TemplateSection(_text, 'Main point 1',
        hint: 'The first big idea, in your own words'),
    TemplateSection(_text, 'Main point 2', hint: 'The second idea'),
    TemplateSection(_text, 'Main point 3', hint: 'The third idea'),
    TemplateSection(_text, 'Scriptures referenced',
        hint: 'Type John 3:16 to link it.'),
    TemplateSection(_text, 'Application',
        hint: 'What will you do this week?'),
    TemplateSection(_text, 'Pray', hint: 'Prayer prompts, or your own words.'),
  ],
);

const _prayerJournal = NoteTemplate(
  id: 'builtin:prayer_journal',
  name: 'Prayer journal',
  icon: 'pray',
  builtIn: true,
  subtitle: 'Praise · Confess · Thanks · Requests',
  sections: [
    TemplateSection(_field, 'Date'),
    TemplateSection(_text, 'Praise', hint: 'Who God is today'),
    TemplateSection(_text, 'Confess', hint: 'What to bring into the light'),
    TemplateSection(_text, 'Thanks', hint: 'What you are grateful for'),
    TemplateSection(_bullet, 'Requests', hint: 'For yourself and for others'),
  ],
);

const _bibleStudy = NoteTemplate(
  id: 'builtin:bible_study',
  name: 'Bible study',
  icon: 'book',
  builtIn: true,
  subtitle: 'Passage · Observe · Interpret · Apply',
  sections: [
    TemplateSection(_scripture, 'Passage'),
    TemplateSection(_bullet, 'Observe', hint: 'What does the text say?'),
    TemplateSection(_text, 'Interpret', hint: 'What does it mean?'),
    TemplateSection(_text, 'Apply', hint: 'What will you do about it?'),
  ],
);

const _smallGroup = NoteTemplate(
  id: 'builtin:small_group',
  name: 'Small group',
  icon: 'group',
  builtIn: true,
  subtitle: 'Host · Attendees · Questions · Takeaways',
  sections: [
    TemplateSection(_field, 'Host'),
    TemplateSection(_field, 'Date'),
    TemplateSection(_text, 'Attendees', hint: 'Who was there'),
    TemplateSection(_bullet, 'Questions', hint: 'What came up'),
    TemplateSection(_bullet, 'Takeaways', hint: 'What stood out'),
    TemplateSection(_checklist, 'Follow-up', hint: 'Who does what next'),
  ],
);

const _devotional = NoteTemplate(
  id: 'builtin:devotional',
  name: 'Devotional',
  icon: 'sunrise',
  builtIn: true,
  subtitle: 'Reading · Stood out · Verse · Response',
  sections: [
    TemplateSection(_field, 'Date'),
    TemplateSection(_text, 'Reading', hint: 'What you read today'),
    TemplateSection(_text, 'Stood out', hint: 'A word or line that caught you'),
    TemplateSection(_scripture, 'Verse'),
    TemplateSection(_text, 'Response', hint: 'How will you respond?'),
  ],
);

const builtInTemplates = <NoteTemplate>[
  sermonTemplate,
  _prayerJournal,
  _bibleStudy,
  _smallGroup,
  _devotional,
];

NoteTemplate? builtInTemplateById(String id) =>
    builtInTemplates.where((t) => t.id == id).firstOrNull;
