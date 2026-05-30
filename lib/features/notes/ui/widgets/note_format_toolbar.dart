import 'package:flutter/material.dart';

/// Thin formatting bar pinned above the keyboard in the note editor. Buttons
/// wrap the current selection in markdown markers or start a `[[` link.
class NoteFormatToolbar extends StatelessWidget {
  const NoteFormatToolbar({
    super.key,
    required this.onBold,
    required this.onItalic,
    required this.onLink,
  });

  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onLink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              const SizedBox(width: 8),
              _ToolButton(
                icon: Icons.format_bold,
                tooltip: 'Bold',
                onPressed: onBold,
              ),
              _ToolButton(
                icon: Icons.format_italic,
                tooltip: 'Italic',
                onPressed: onItalic,
              ),
              _ToolButton(
                icon: Icons.add_link,
                tooltip: 'Insert link',
                onPressed: onLink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 22),
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
    );
  }
}
