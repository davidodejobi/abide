import 'package:material_ui/material_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/widgets/lum_group_card.dart';

/// Small uppercase section label above a card (Figma "READING").
class YouSectionLabel extends StatelessWidget {
  const YouSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          LumSpace.xs, LumSpace.xl, LumSpace.xs, LumSpace.sm),
      child: Semantics(
        header: true,
        child: Text(
          text.toUpperCase(),
          style: LumText.footnoteEmphasized.copyWith(
            color: context.lum.textSecondary,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

/// A [LumGroupCard] whose rows are split by a hairline.
class YouGroup extends StatelessWidget {
  const YouGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final line = context.lum.borderSubtle;
    return LumGroupCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: line),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// One tappable (or static, when [onTap] is null) row: icon, title, quiet
/// subtitle and a chevron. Grows with text scale.
class YouRow extends StatelessWidget {
  const YouRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: LumSpace.lg, vertical: LumSpace.md),
        child: Row(
          children: [
            Icon(icon, size: LumSize.iconMd, color: c.iconDefault),
            const SizedBox(width: LumSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: LumText.bodyEmphasized
                          .copyWith(color: c.textPrimary)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: LumText.subheadline
                            .copyWith(color: c.textSecondary)),
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: LumSpace.sm),
              Icon(PhosphorIcons.caretRight(),
                  size: LumSize.iconSm, color: c.iconSecondary),
            ],
          ],
        ),
      ),
    );
    return Semantics(
      container: true,
      button: onTap != null,
      label: subtitle == null ? title : '$title, $subtitle',
      excludeSemantics: true,
      onTap: onTap,
      child: onTap == null
          ? row
          : InkWell(onTap: onTap, child: row),
    );
  }
}

/// A row that holds a control under its title (theme chips, font size, ...).
class YouControlRow extends StatelessWidget {
  const YouControlRow({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Padding(
      padding: const EdgeInsets.all(LumSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: LumSize.iconMd, color: c.iconDefault),
              const SizedBox(width: LumSpace.lg),
              Expanded(
                child: Text(title,
                    style:
                        LumText.bodyEmphasized.copyWith(color: c.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: LumSpace.md),
          child,
        ],
      ),
    );
  }
}

/// One choice in a [showYouPicker] sheet. [id] null means "follow my reading".
class YouChoice {
  const YouChoice({required this.id, required this.label});

  final String? id;
  final String label;
}

/// Bottom sheet that lists [options] and returns the tapped one.
Future<YouChoice?> showYouPicker(
  BuildContext context, {
  required String title,
  required List<YouChoice> options,
  required String? selected,
}) {
  return showModalBottomSheet<YouChoice>(
    useRootNavigator: true,
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final c = context.lum;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              LumSpace.sm, 0, LumSpace.sm, LumSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            LumSpace.md, LumSpace.xs, LumSpace.md, LumSpace.md),
                        child: Semantics(
                          header: true,
                          child: Text(title,
                              style: LumText.title2.copyWith(color: c.textPrimary)),
                        ),
                      ),
                      for (final o in options)
                        Semantics(
                          button: true,
                          selected: o.id == selected,
                          label: o.label,
                          excludeSemantics: true,
                          onTap: () => Navigator.of(context).pop(o),
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(o),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                  minHeight: LumSize.touchTarget),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: LumSpace.md,
                                    vertical: LumSpace.sm),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(o.label,
                                          style: LumText.body
                                              .copyWith(color: c.textPrimary)),
                                    ),
                                    if (o.id == selected)
                                      Icon(Icons.check_rounded,
                                          color: c.iconDefault),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
