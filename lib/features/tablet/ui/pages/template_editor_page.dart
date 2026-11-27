import 'package:auto_route/auto_route.dart' show RoutePage;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/widgets/lum_circle_button.dart';
import 'package:openbaptisthymnal/core/widgets/lum_page_background.dart';
import 'package:openbaptisthymnal/features/tablet/domain/note_template.dart';
import 'package:openbaptisthymnal/features/tablet/providers/templates_providers.dart';
import 'package:openbaptisthymnal/features/tablet/ui/notes_strings.dart';
import 'package:openbaptisthymnal/features/tablet/ui/template_icons.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/new_note_sheet.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/template_sheets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Create or edit one of the user's templates. With [templateId] it edits that
/// template; otherwise it starts a new one, optionally pre-filled (Save as
/// template from a note).
@RoutePage()
class TemplateEditorPage extends ConsumerWidget {
  const TemplateEditorPage({
    super.key,
    this.templateId,
    this.initialName = '',
    this.initialIcon = 'church',
    this.initialSections = const [],
  });

  final String? templateId;
  final String initialName;
  final String initialIcon;
  final List<TemplateSection> initialSections;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = templateId;
    if (id == null) {
      return TemplateForm(
        name: initialName,
        icon: initialIcon,
        sections: initialSections,
      );
    }
    // Mine loads from a stream, so wait for it before seeding the form.
    return ref.watch(myTemplatesProvider).maybeWhen(
          data: (mine) {
            final t = mine.where((t) => t.id == id).firstOrNull;
            if (t == null) return const Scaffold(body: SizedBox.shrink());
            return TemplateForm(
              key: ValueKey(t.id),
              id: t.id,
              name: t.name,
              icon: t.icon,
              sections: t.sections,
            );
          },
          orElse: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
        );
  }
}

class _Item {
  _Item(this.section);
  final Key key = UniqueKey();
  TemplateSection section;
}

class TemplateForm extends HookConsumerWidget {
  const TemplateForm({
    super.key,
    this.id,
    required this.name,
    required this.icon,
    required this.sections,
  });

  final String? id;
  final String name;
  final String icon;
  final List<TemplateSection> sections;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lum;
    final nameController = useTextEditingController(text: name);
    final nameText = useValueListenable(nameController).text.trim();
    final iconKey = useState(icon);
    final items = useState([for (final s in sections) _Item(s)]);

    List<TemplateSection> current() => [for (final i in items.value) i.section];

    Future<String?> askName(String initial) async {
      final result = await showDialog<String>(
        context: context,
        builder: (_) => _RenameDialog(initial: initial),
      );
      final t = result?.trim();
      return t == null || t.isEmpty ? null : t;
    }

    Future<void> rename(_Item item) async {
      final next = await askName(item.section.label);
      if (next == null) return;
      item.section = item.section.copyWith(label: next);
      items.value = [...items.value]; // rebuild
    }

    Future<void> addSection() async {
      final type = await showModalBottomSheet<TemplateSectionType>(
        useRootNavigator: true,
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final t in TemplateSectionType.values)
                SheetRow(
                  icon: sectionTypeIcon(t.name),
                  title: NotesStrings.sectionType(t),
                  hint: NotesStrings.sectionTypeHint(t),
                  onTap: () => Navigator.of(sheetContext).pop(t),
                ),
              const SizedBox(height: LumSpace.sm),
            ],
          ),
        ),
      );
      if (type == null) return;
      final item = _Item(TemplateSection(type, NotesStrings.sectionType(type)));
      items.value = [...items.value, item];
      if (context.mounted) await rename(item);
    }

    Future<void> save() async {
      final navigator = Navigator.of(context);
      await ref.read(templatesRepositoryProvider).save(
            id: id,
            name: nameText,
            icon: iconKey.value,
            sections: current(),
          );
      navigator.maybePop();
    }

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(LumSpace.lg),
          decoration: BoxDecoration(
            color: c.bgSurface,
            borderRadius: BorderRadius.circular(LumRadius.lg),
            border: Border.all(color: c.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TemplateIconTile(icon: templateIcon(iconKey.value)),
                  const SizedBox(width: LumSpace.md),
                  Expanded(
                    child: TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.sentences,
                      style: LumText.headline.copyWith(color: c.textPrimary),
                      decoration: const InputDecoration(
                        labelText: NotesStrings.templateName,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: LumSpace.md),
              Text(NotesStrings.iconLabel,
                  style: LumText.footnote.copyWith(color: c.textSecondary)),
              const SizedBox(height: LumSpace.sm),
              Wrap(
                spacing: LumSpace.sm,
                runSpacing: LumSpace.sm,
                children: [
                  for (final key in templateIconKeys)
                    Semantics(
                      button: true,
                      selected: key == iconKey.value,
                      label: NotesStrings.iconName(key),
                      excludeSemantics: true,
                      onTap: () => iconKey.value = key,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => iconKey.value = key,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: key == iconKey.value
                                ? c.bgPrimary
                                : c.bgSurfaceSunken,
                          ),
                          child: Icon(templateIcon(key),
                              size: 22,
                              color: key == iconKey.value
                                  ? c.textOnPrimary
                                  : c.textPrimary),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, LumSpace.xl, 0, LumSpace.sm),
          child: Row(
            children: [
              Semantics(
                  header: true,
                  child: Text(NotesStrings.sectionsLabel,
                      style: LumText.title3.copyWith(color: c.textPrimary)),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  '${NotesStrings.sectionCount(items.value.length)} · '
                  '${NotesStrings.dragToReorder.toLowerCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LumText.footnote.copyWith(color: c.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final footer = Padding(
      padding: const EdgeInsets.only(top: LumSpace.sm),
      child: Semantics(
        button: true,
        label: NotesStrings.addSection,
        excludeSemantics: true,
        onTap: addSection,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: addSection,
          child: Container(
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(LumRadius.md),
              border: Border.all(color: c.borderStrong),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIcons.plus(), size: 20, color: c.textPrimary),
                const SizedBox(width: LumSpace.sm),
                Text(NotesStrings.addSection,
                    style: LumText.headline.copyWith(color: c.textPrimary)),
              ],
            ),
          ),
        ),
      ),
    );

    final canSave = nameText.isNotEmpty;

    return LumPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(LumSize.screenGutter,
                    LumSpace.md, LumSize.screenGutter, LumSpace.sm),
                child: Row(
                  children: [
                    LumCircleButton(
                      icon: PhosphorIcons.x(),
                      label: NotesStrings.close,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          id == null
                              ? NotesStrings.newTemplate
                              : NotesStrings.editTemplate,
                          textAlign: TextAlign.center,
                          style:
                              LumText.headline.copyWith(color: c.textPrimary),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => showSectionsPreview(
                        context,
                        name: nameText,
                        icon: iconKey.value,
                        sections: current(),
                      ),
                      child: const Text(NotesStrings.preview),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ReorderableListView(
                  padding: const EdgeInsets.fromLTRB(
                      LumSize.screenGutter, 0, LumSize.screenGutter, LumSpace.lg),
                  header: header,
                  footer: footer,
                  buildDefaultDragHandles: false,
                  onReorderItem: (oldIndex, newIndex) {
                    final next = [...items.value];
                    next.insert(newIndex, next.removeAt(oldIndex));
                    items.value = next;
                  },
                  children: [
                    for (final (index, item) in items.value.indexed)
                      _SectionRow(
                        key: item.key,
                        index: index,
                        section: item.section,
                        onRename: () => rename(item),
                        onRemove: () => items.value = [
                          for (final i in items.value)
                            if (i != item) i,
                        ],
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(LumSize.screenGutter,
                    LumSpace.sm, LumSize.screenGutter, LumSpace.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!canSave)
                      Padding(
                        padding: const EdgeInsets.only(bottom: LumSpace.sm),
                        child: Text(NotesStrings.templateNameHint,
                            style: LumText.footnote
                                .copyWith(color: c.textSecondary)),
                      ),
                    Semantics(
                      button: true,
                      enabled: canSave,
                      label: NotesStrings.saveTemplate,
                      excludeSemantics: true,
                      onTap: canSave ? save : null,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: canSave ? save : null,
                        child: Container(
                          height: 50,
                          width: double.infinity,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: canSave ? c.bgPrimary : c.bgSurfaceSunken,
                            borderRadius: BorderRadius.circular(LumRadius.md),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(PhosphorIcons.check(),
                                  size: 20,
                                  color: canSave
                                      ? c.textOnPrimary
                                      : c.textDisabled),
                              const SizedBox(width: LumSpace.sm),
                              Text(NotesStrings.saveTemplate,
                                  style: LumText.headline.copyWith(
                                      color: canSave
                                          ? c.textOnPrimary
                                          : c.textDisabled)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({
    super.key,
    required this.index,
    required this.section,
    required this.onRename,
    required this.onRemove,
  });

  final int index;
  final TemplateSection section;
  final VoidCallback onRename;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Padding(
      padding: const EdgeInsets.only(bottom: LumSpace.sm),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        decoration: BoxDecoration(
          color: c.bgSurface,
          borderRadius: BorderRadius.circular(LumRadius.md),
          border: Border.all(color: c.borderSubtle),
        ),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Semantics(
                label: NotesStrings.dragToReorder,
                child: SizedBox(
                  width: 44,
                  height: 52,
                  child: Icon(PhosphorIcons.dotsSixVertical(),
                      size: 20, color: c.iconSecondary),
                ),
              ),
            ),
            Expanded(
              child: Semantics(
                button: true,
                label: '${section.label}. ${NotesStrings.renameSection}',
                excludeSemantics: true,
                onTap: onRename,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onRename,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: LumSpace.md),
                    child: Text(section.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LumText.body
                            .copyWith(color: c.textPrimary, fontSize: 17)),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: LumSpace.md, vertical: 6),
              decoration: BoxDecoration(
                color: c.bgSurfaceSunken,
                borderRadius: BorderRadius.circular(LumRadius.full),
              ),
              child: Text(NotesStrings.sectionType(section.type),
                  style: LumText.footnote.copyWith(color: c.textSecondary)),
            ),
            IconButton(
              tooltip: NotesStrings.removeSection,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              icon: Icon(PhosphorIcons.x(), size: 18, color: c.textSecondary),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

/// Owns its controller, so it is disposed with the dialog and not while the
/// route is still animating away.
class _RenameDialog extends HookWidget {
  const _RenameDialog({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: initial);
    void done() => Navigator.of(context).pop(controller.text);
    return AlertDialog(
      title: const Text(NotesStrings.renameSection),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: NotesStrings.sectionName),
        onSubmitted: (_) => done(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(NotesStrings.cancel),
        ),
        TextButton(onPressed: done, child: const Text(NotesStrings.save)),
      ],
    );
  }
}
