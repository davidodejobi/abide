import 'package:auto_route/auto_route.dart';
import 'package:flutter/semantics.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/widgets/lum_circle_button.dart';
import 'package:openbaptisthymnal/core/widgets/lum_group_card.dart';
import 'package:openbaptisthymnal/core/widgets/lum_page_background.dart';
import 'package:openbaptisthymnal/features/tablet/domain/builtin_templates.dart';
import 'package:openbaptisthymnal/features/tablet/domain/note_template.dart';
import 'package:openbaptisthymnal/features/tablet/providers/templates_providers.dart';
import 'package:openbaptisthymnal/features/tablet/ui/notes_strings.dart';
import 'package:openbaptisthymnal/features/tablet/ui/template_icons.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/new_note_sheet.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/template_sheets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Manage templates: Pinned (reorder), Mine (edit, delete with undo) and
/// Built-in (duplicate only).
@RoutePage()
class ManageTemplatesPage extends ConsumerWidget {
  const ManageTemplatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lum;
    final pins = ref.watch(pinnedTemplateIdsProvider);
    final mine = ref.watch(myTemplatesProvider).valueOrNull ?? const [];
    final all = [...builtInTemplates, ...mine];
    final pinned = [
      for (final id in pins)
        if (all.where((t) => t.id == id).firstOrNull case final t?) t,
    ];

    Widget header(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(
              LumSpace.xs, LumSpace.xl, 0, LumSpace.sm),
          child: Semantics(
            header: true,
            child: Text(text,
                style: LumText.footnoteEmphasized
                    .copyWith(color: c.textSecondary)),
          ),
        );

    return LumPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(LumSize.screenGutter, LumSpace.md,
                LumSize.screenGutter, LumSpace.xxxl),
            children: [
              Row(
                children: [
                  LumCircleButton(
                    icon: PhosphorIcons.caretLeft(),
                    label: NotesStrings.back,
                    onPressed: () => context.router.maybePop(),
                  ),
                  const Spacer(),
                  LumCircleButton(
                    icon: PhosphorIcons.plus(),
                    label: NotesStrings.createTemplate,
                    onPressed: () => context.router.push(TemplateEditorRoute()),
                  ),
                ],
              ),
              const SizedBox(height: LumSpace.md),
              Semantics(
                header: true,
                child: Text(NotesStrings.templates,
                    style: LumText.largeTitle.copyWith(color: c.textPrimary)),
              ),
              if (pinned.isNotEmpty) ...[
                header(NotesStrings.pinnedManageHeader),
                LumGroupCard(
                  child: ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    onReorderItem: (a, b) => ref
                        .read(pinnedTemplateIdsProvider.notifier)
                        .reorder(a, b),
                    children: [
                      for (final (i, t) in pinned.indexed)
                        _PinnedRow(key: ValueKey(t.id), index: i, template: t),
                    ],
                  ),
                ),
              ],
              header(NotesStrings.mine),
              if (mine.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(LumSpace.md),
                  child: Text(NotesStrings.noOwnTemplates,
                      style: LumText.subheadline
                          .copyWith(color: c.textSecondary)),
                )
              else
                LumGroupCard(
                  child: Column(
                    children: [
                      for (final t in mine) _MineRow(template: t),
                    ],
                  ),
                ),
              header(NotesStrings.builtIn),
              LumGroupCard(
                child: Column(
                  children: [
                    for (final t in builtInTemplates) _BuiltInRow(template: t),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    LumSpace.xs, LumSpace.md, LumSpace.xs, 0),
                child: Text(NotesStrings.builtInFootnote,
                    style: LumText.footnote.copyWith(color: c.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowShell extends StatelessWidget {
  const _RowShell({
    required this.template,
    required this.subtitle,
    required this.trailing,
    this.leading,
    this.onTap,
    this.onLongPress,
  });

  final NoteTemplate template;
  final String subtitle;
  final Widget trailing;
  final Widget? leading;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 58),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: LumSpace.md, vertical: LumSpace.sm),
          child: Row(
            children: [
              if (leading != null) leading!,
              TemplateIconTile(icon: templateIcon(template.icon)),
              const SizedBox(width: LumSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(template.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LumText.headline
                            .copyWith(color: c.textPrimary, fontSize: 16)),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LumText.footnote
                            .copyWith(color: c.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _PinnedRow extends ConsumerWidget {
  const _PinnedRow({super.key, required this.index, required this.template});

  final int index;
  final NoteTemplate template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lum;
    return _RowShell(
      template: template,
      subtitle: template.builtIn
          ? '${NotesStrings.pinned} · ${NotesStrings.builtIn.toLowerCase()}'
          : NotesStrings.pinned,
      leading: ReorderableDragStartListener(
        index: index,
        child: Semantics(
          label: NotesStrings.dragToReorder,
          child: SizedBox(
            width: 32,
            height: 44,
            child: Icon(PhosphorIcons.dotsSixVertical(),
                size: 20, color: c.iconSecondary),
          ),
        ),
      ),
      trailing: IconButton(
        tooltip: NotesStrings.unpin,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        icon: Icon(PhosphorIconsFill.pushPin, size: 20, color: c.textAccent),
        onPressed: () =>
            ref.read(pinnedTemplateIdsProvider.notifier).unpin(template.id),
      ),
    );
  }
}

class _MineRow extends ConsumerWidget {
  const _MineRow({required this.template});

  final NoteTemplate template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lum;
    final repo = ref.read(templatesRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    void delete() {
      repo.delete(template.id);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(NotesStrings.templateDeleted(template.name)),
          action: SnackBarAction(
            label: NotesStrings.undo,
            onPressed: () => repo.restore(template.id),
          ),
        ));
    }

    void edit() =>
        context.router.push(TemplateEditorRoute(templateId: template.id));

    void more() {
      final isPinned =
          ref.read(pinnedTemplateIdsProvider).contains(template.id);
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SheetRow(
                icon: PhosphorIcons.pencilSimple(),
                title: NotesStrings.edit,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  edit();
                },
              ),
              SheetRow(
                icon: PhosphorIcons.pushPin(),
                title: isPinned ? NotesStrings.unpin : NotesStrings.pin,
                onTap: () {
                  ref
                      .read(pinnedTemplateIdsProvider.notifier)
                      .toggle(template.id);
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
                icon: PhosphorIcons.trash(),
                title: NotesStrings.delete,
                destructive: true,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  delete();
                },
              ),
              const SizedBox(height: LumSpace.sm),
            ],
          ),
        ),
      );
    }

    return Semantics(
      customSemanticsActions: {
        const CustomSemanticsAction(label: NotesStrings.delete): delete,
      },
      child: Dismissible(
        key: ValueKey('mine-${template.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: LumSpace.xl),
          color: c.bgDangerContainer,
          child: Icon(PhosphorIcons.trash(), color: c.textOnDangerContainer),
        ),
        onDismissed: (_) => delete(),
        child: _RowShell(
          template: template,
          subtitle: NotesStrings.sectionCount(template.sections.length),
          onTap: edit,
          onLongPress: more,
          trailing: IconButton(
            tooltip: NotesStrings.mediaMore,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: Icon(PhosphorIcons.dotsThree(), color: c.textSecondary),
            onPressed: more,
          ),
        ),
      ),
    );
  }
}

class _BuiltInRow extends ConsumerWidget {
  const _BuiltInRow({required this.template});

  final NoteTemplate template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lum;
    final messenger = ScaffoldMessenger.of(context);
    return _RowShell(
      template: template,
      subtitle: NotesStrings.builtIn,
      onLongPress: () => showTemplateMenu(context, ref, template),
      trailing: TextButton.icon(
        onPressed: () => duplicateTemplate(ref, messenger, template),
        icon: Icon(PhosphorIcons.copy(), size: 18, color: c.textSecondary),
        label: Text(NotesStrings.duplicate,
            style: LumText.subheadline.copyWith(color: c.textPrimary)),
      ),
    );
  }
}
