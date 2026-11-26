import 'dart:convert';

/// The six kinds of section a template can hold.
///
/// * [heading]: a bare `## Label` divider.
/// * [text], [bullet], [checklist]: `## Label` followed by an empty
///   paragraph, bullet or to-do. [TemplateSection.hint] is the placeholder
///   shown in that empty block; it is never saved into the note.
/// * [scripture]: a `**Label:** ` line for a passage.
/// * [field]: a `**Label:** value` line (speaker, place, date...).
enum TemplateSectionType { heading, text, bullet, checklist, scripture, field }

class TemplateSection {
  const TemplateSection(this.type, this.label, {this.hint = ''});

  final TemplateSectionType type;
  final String label;
  final String hint;

  TemplateSection copyWith({TemplateSectionType? type, String? label}) =>
      TemplateSection(type ?? this.type, label ?? this.label, hint: hint);

  Map<String, String> toJson() =>
      {'type': type.name, 'label': label, 'hint': hint};

  static TemplateSection? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final type = TemplateSectionType.values
        .where((t) => t.name == json['type'])
        .firstOrNull;
    final label = json['label'];
    if (type == null || label is! String) return null;
    final hint = json['hint'];
    return TemplateSection(type, label, hint: hint is String ? hint : '');
  }

  @override
  bool operator ==(Object other) =>
      other is TemplateSection &&
      other.type == type &&
      other.label == label &&
      other.hint == hint;

  @override
  int get hashCode => Object.hash(type, label, hint);
}

/// The six icon choices in the template builder, by storage key.
const templateIconKeys = <String>[
  'church',
  'book',
  'pray',
  'group',
  'sunrise',
  'heart',
];

class NoteTemplate {
  const NoteTemplate({
    required this.id,
    required this.name,
    required this.icon,
    required this.sections,
    this.builtIn = false,
    this.subtitle,
  });

  final String id;
  final String name;
  final String icon;
  final List<TemplateSection> sections;

  /// Built-ins are const data: they cannot be edited or deleted, only
  /// duplicated.
  final bool builtIn;

  /// Picker subtitle; falls back to the section labels.
  final String? subtitle;

  String get summary =>
      subtitle ??
      sections
          .map((s) => s.label.trim())
          .where((l) => l.isNotEmpty)
          .take(4)
          .join(' · ');

  NoteTemplate copyWith({
    String? id,
    String? name,
    String? icon,
    List<TemplateSection>? sections,
  }) =>
      NoteTemplate(
        id: id ?? this.id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        sections: sections ?? this.sections,
      );
}

String encodeSections(List<TemplateSection> sections) =>
    jsonEncode([for (final s in sections) s.toJson()]);

/// Tolerant: a malformed row yields no sections rather than a crash.
List<TemplateSection> decodeSections(String json) {
  try {
    final raw = jsonDecode(json);
    if (raw is! List) return const [];
    return [
      for (final e in raw)
        if (TemplateSection.tryFromJson(e) case final s?) s,
    ];
  } on FormatException {
    return const [];
  }
}
