import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/features/tablet/domain/builtin_templates.dart';
import 'package:openbaptisthymnal/features/tablet/domain/note_template.dart';
import 'package:openbaptisthymnal/features/tablet/providers/templates_providers.dart';
import 'package:openbaptisthymnal/features/tablet/ui/notes_strings.dart';
import 'package:openbaptisthymnal/features/tablet/ui/template_icons.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/template_sheets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// What the picker returned: a blank note, a template (by id), or the
/// template builder.
sealed class NewNoteChoice {
  const NewNoteChoice();
}

class BlankNoteChoice extends NewNoteChoice {
  const BlankNoteChoice();
}

class TemplateNoteChoice extends NewNoteChoice {
  const TemplateNoteChoice(this.templateId);
  final String templateId;
}

class CreateTemplateChoice extends NewNoteChoice {
  const CreateTemplateChoice();
}

/// Shows the New note picker and opens whatever was chosen. The one entry
/// point for the Notes button and the empty state.
Future<void> startNewNote(BuildContext context) async {
  final router = context.router;
  final choice = await showModalBottomSheet<NewNoteChoice>(
    useRootNavigator: true,
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.9,
    ),
    builder: (_) => const NewNoteSheet(),
  );
  switch (choice) {
    case null:
      return;
    case BlankNoteChoice():
      router.push(TabletEditorRoute());
    case TemplateNoteChoice(:final templateId):
      router.push(TabletEditorRoute(templateId: templateId));
    case CreateTemplateChoice():
      router.push(TemplateEditorRoute());
  }
}

/// New note picker: Blank, Pinned, Mine, Built-in, then Create template.
/// Hold a card to pin, unpin, duplicate or preview it.
class NewNoteSheet extends ConsumerWidget {
  const NewNoteSheet({super.key});

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
    final rest = all.where((t) => !pins.contains(t.id));
    final mineRest = rest.where((t) => !t.builtIn).toList();
    final builtInRest = rest.where((t) => t.builtIn).toList();

    void pick(NewNoteChoice choice) => Navigator.of(context).pop(choice);

    Widget label(String text, {String? trailing}) => Padding(
          padding: const EdgeInsets.fromLTRB(0, LumSpace.lg, 0, LumSpace.sm),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(text,
                      style: LumText.footnoteEmphasized
                          .copyWith(color: c.textSecondary)),
                ),
              ),
              if (trailing != null)
                Text(trailing,
                    style: LumText.footnote.copyWith(color: c.textSecondary)),
            ],
          ),
        );

    Widget card(NoteTemplate t, {bool isPinned = false}) => Padding(
          padding: const EdgeInsets.only(bottom: LumSpace.sm),
          child: TemplateCard(
            template: t,
            pinned: isPinned,
            onTap: () => pick(TemplateNoteChoice(t.id)),
            onLongPress: () => showTemplateMenu(context, ref, t),
          ),
        );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            LumSize.screenGutter, 0, LumSize.screenGutter, LumSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(NotesStrings.newNote,
                        style: LumText.title2.copyWith(color: c.textPrimary)),
                  ),
                ),
                IconButton(
                  tooltip: NotesStrings.close,
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  icon: Icon(PhosphorIcons.x(), color: c.textPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: LumSpace.sm),
            _BlankCard(onTap: () => pick(const BlankNoteChoice())),
            if (pinned.isNotEmpty) ...[
              label(NotesStrings.pinned, trailing: NotesStrings.pinnedPickerHint),
              for (final t in pinned) card(t, isPinned: true),
            ],
            if (mineRest.isNotEmpty) ...[
              label(NotesStrings.mine),
              for (final t in mineRest) card(t),
            ],
            if (builtInRest.isNotEmpty) ...[
              label(NotesStrings.builtIn),
              for (final t in builtInRest) card(t),
            ],
            const SizedBox(height: LumSpace.sm),
            _OutlineButton(
              icon: PhosphorIcons.plus(),
              label: NotesStrings.createTemplate,
              onTap: () => pick(const CreateTemplateChoice()),
            ),
          ],
        ),
      ),
    );
  }
}

const double _cardHeight = 58;

class _BlankCard extends StatelessWidget {
  const _BlankCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Semantics(
      button: true,
      label: '${NotesStrings.blankNote}. ${NotesStrings.blankNoteHint}',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: _cardHeight - 2,
          padding: const EdgeInsets.symmetric(horizontal: LumSpace.md),
          decoration: BoxDecoration(
            color: c.bgPrimary,
            borderRadius: BorderRadius.circular(LumRadius.md),
          ),
          child: Row(
            children: [
              TemplateIconTile(
                  icon: PhosphorIcons.notebook(),
                  background: c.textOnPrimary,
                  foreground: c.bgPrimary),
              const SizedBox(width: LumSpace.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(NotesStrings.blankNote,
                        style: LumText.headline
                            .copyWith(color: c.textOnPrimary, fontSize: 15)),
                    Text(NotesStrings.blankNoteHint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LumText.footnote
                            .copyWith(color: c.textOnPrimary, fontSize: 12)),
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

/// A 36pt rounded icon tile.
class TemplateIconTile extends StatelessWidget {
  const TemplateIconTile(
      {super.key, required this.icon, this.background, this.foreground});

  final IconData icon;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: background ?? c.bgAccentContainer,
        borderRadius: BorderRadius.circular(LumRadius.md),
      ),
      child: Icon(icon, size: 20, color: foreground ?? c.textOnAccentContainer),
    );
  }
}

/// A template row for the picker: 58pt, 36pt icon tile, name over a one-line
/// summary. Pinned cards get a 1pt border and a pin, no fill.
class TemplateCard extends StatelessWidget {
  const TemplateCard({
    super.key,
    required this.template,
    required this.onTap,
    required this.onLongPress,
    this.pinned = false,
  });

  final NoteTemplate template;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Semantics(
      button: true,
      label: '${template.name}. ${template.summary}',
      hint: NotesStrings.pinnedPickerHint,
      excludeSemantics: true,
      onTap: onTap,
      onLongPress: onLongPress,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          constraints: const BoxConstraints(minHeight: _cardHeight),
          padding: const EdgeInsets.symmetric(
              horizontal: LumSpace.md, vertical: LumSpace.sm),
          decoration: BoxDecoration(
            color: pinned ? null : c.bgSurface,
            borderRadius: BorderRadius.circular(LumRadius.md),
            border: Border.all(
                color: pinned ? c.textAccent : c.borderSubtle),
          ),
          child: Row(
            children: [
              TemplateIconTile(icon: templateIcon(template.icon)),
              const SizedBox(width: LumSpace.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(template.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LumText.headline
                            .copyWith(color: c.textPrimary, fontSize: 15)),
                    Text(template.summary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LumText.footnote
                            .copyWith(color: c.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              if (pinned)
                Icon(PhosphorIconsFill.pushPin, size: 18, color: c.textAccent),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LumRadius.md),
            border: Border.all(color: c.textPrimary),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: c.textPrimary),
              const SizedBox(width: LumSpace.sm),
              Text(label,
                  style: LumText.headline.copyWith(color: c.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}
