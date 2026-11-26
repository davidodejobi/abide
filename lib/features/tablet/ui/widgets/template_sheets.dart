import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/features/tablet/domain/note_template.dart';
import 'package:openbaptisthymnal/features/tablet/providers/templates_providers.dart';
import 'package:openbaptisthymnal/features/tablet/ui/notes_strings.dart';
import 'package:openbaptisthymnal/features/tablet/ui/template_icons.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const double sheetRowHeight = 52;

/// One 52pt row in a sheet: 28pt icon tile, 17pt title, optional 13pt hint.
class SheetRow extends StatelessWidget {
  const SheetRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.hint,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? hint;
  final bool destructive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    final color = destructive ? c.textDanger : c.textPrimary;
    return Semantics(
      button: true,
      label: hint == null ? title : '$title. $hint',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: sheetRowHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: LumSize.screenGutter, vertical: LumSpace.xs),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: c.bgSurfaceSunken,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: LumSpace.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: LumText.body
                              .copyWith(color: color, fontSize: 17)),
                      if (hint != null)
                        Text(hint!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: LumText.footnote
                                .copyWith(color: c.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Long-press menu for a template: pin or unpin, duplicate, preview.
Future<void> showTemplateMenu(
  BuildContext context,
  WidgetRef ref,
  NoteTemplate template,
) {
  final messenger = ScaffoldMessenger.of(context);
  final pins = ref.read(pinnedTemplateIdsProvider.notifier);
  final isPinned = ref.read(pinnedTemplateIdsProvider).contains(template.id);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetRow(
            icon: PhosphorIcons.pushPin(),
            title: isPinned ? NotesStrings.unpin : NotesStrings.pin,
            onTap: () {
              pins.toggle(template.id);
              Navigator.of(sheetContext).pop();
            },
          ),
          SheetRow(
            icon: PhosphorIcons.copy(),
            title: NotesStrings.duplicate,
            onTap: () {
              Navigator.of(sheetContext).pop();
              duplicateTemplate(ref, messenger, template);
            },
          ),
          SheetRow(
            icon: PhosphorIcons.eye(),
            title: NotesStrings.previewSections,
            onTap: () {
              Navigator.of(sheetContext).pop();
              showTemplatePreview(context, template);
            },
          ),
          const SizedBox(height: LumSpace.sm),
        ],
      ),
    ),
  );
}

Future<void> duplicateTemplate(
  WidgetRef ref,
  ScaffoldMessengerState messenger,
  NoteTemplate template,
) async {
  await ref
      .read(templatesRepositoryProvider)
      .duplicate(template, NotesStrings.copyName(template.name));
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text(NotesStrings.addedToMine)));
}

/// Read-only list of a template's sections and their types.
Future<void> showTemplatePreview(BuildContext context, NoteTemplate template) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PreviewSheet(
      name: template.name,
      icon: template.icon,
      sections: template.sections,
    ),
  );
}

/// Preview of sections that are not saved yet (the builder's Preview).
Future<void> showSectionsPreview(
  BuildContext context, {
  required String name,
  required String icon,
  required List<TemplateSection> sections,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PreviewSheet(name: name, icon: icon, sections: sections),
  );
}

class _PreviewSheet extends StatelessWidget {
  const _PreviewSheet(
      {required this.name, required this.icon, required this.sections});

  final String name;
  final String icon;
  final List<TemplateSection> sections;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(LumSize.screenGutter, 0,
                LumSize.screenGutter, LumSpace.sm),
            child: Semantics(
              header: true,
              child: Text(name.trim().isEmpty ? NotesStrings.newTemplate : name,
                  style: LumText.title2.copyWith(color: c.textPrimary)),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final s in sections)
                  SheetRow(
                    icon: sectionTypeIcon(s.type.name),
                    title: s.label.trim().isEmpty ? '...' : s.label,
                    hint: NotesStrings.sectionType(s.type),
                    onTap: () {},
                  ),
              ],
            ),
          ),
          const SizedBox(height: LumSpace.sm),
        ],
      ),
    );
  }
}
