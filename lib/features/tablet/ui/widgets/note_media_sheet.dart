import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/features/tablet/domain/note_media.dart';
import 'package:openbaptisthymnal/features/tablet/ui/notes_strings.dart';

/// Playback speeds offered for recordings, as percentages.
const audioSpeeds = [100, 125, 150, 200];

String speedLabel(int percent) {
  final x = percent / 100;
  return '${x == x.roundToDouble() ? x.toInt() : x}x';
}

/// What the media sheet can do. Each callback acts on the block and returns
/// when done; the sheet rebuilds from the node afterwards.
class NoteMediaSheetActions {
  const NoteMediaSheetActions({
    required this.isAudio,
    required this.attrs,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onSetAttrs,
    required this.onEditText,
    required this.onShare,
    required this.onDelete,
    this.onReplace,
    this.onTranscribe,
  });

  final bool isAudio;

  /// Current attributes of the block, read fresh on every rebuild.
  final Map<String, dynamic> Function() attrs;
  final bool Function() canMoveUp;
  final bool Function() canMoveDown;
  final Future<void> Function() onMoveUp;
  final Future<void> Function() onMoveDown;
  final Future<void> Function(Map<String, dynamic>) onSetAttrs;
  final Future<void> Function() onEditText;
  final Future<void> Function() onShare;
  final Future<void> Function() onDelete;
  final Future<void> Function()? onReplace;

  /// Starts a transcript of this recording (audio blocks only).
  final Future<void> Function()? onTranscribe;
}

/// One sheet style for image and audio: grabber, grouped 48 pt rows, delete
/// alone and red in the last group. Image sheet is about 440 pt so the block
/// stays visible above it while Size and Align change live.
Future<void> showNoteMediaSheet(
  BuildContext context,
  NoteMediaSheetActions actions,
) {
  HapticFeedback.selectionClick();
  return showModalBottomSheet<void>(
    useRootNavigator: true,
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: context.lum.bgElevated,
    builder: (_) => _MediaSheet(actions: actions),
  );
}

class _MediaSheet extends StatefulWidget {
  const _MediaSheet({required this.actions});
  final NoteMediaSheetActions actions;

  @override
  State<_MediaSheet> createState() => _MediaSheetState();
}

class _MediaSheetState extends State<_MediaSheet> {
  NoteMediaSheetActions get a => widget.actions;

  Future<void> _run(Future<void> Function() fn) async {
    await fn();
    if (mounted) setState(() {});
  }

  Future<void> _closeThen(Future<void> Function() fn) async {
    Navigator.of(context).pop();
    await fn();
  }

  @override
  Widget build(BuildContext context) {
    final lum = context.lum;
    final attrs = a.attrs();
    final size = attrs[imageSizeKey] as String? ?? defaultImageSize;
    final align = attrs[imageAlignKey] as String? ?? defaultImageAlign;
    final speed = attrs[audioSpeedKey] as int? ?? 100;

    final rows = <Widget>[
      _Row(
        icon: PhosphorIcons.arrowsVertical(),
        label: NotesStrings.moveLabel,
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          _IconAction(
            icon: PhosphorIcons.arrowUp(),
            label: NotesStrings.moveUp,
            onTap: a.canMoveUp() ? () => _run(a.onMoveUp) : null,
          ),
          _IconAction(
            icon: PhosphorIcons.arrowDown(),
            label: NotesStrings.moveDown,
            onTap: a.canMoveDown() ? () => _run(a.onMoveDown) : null,
          ),
        ]),
      ),
      if (!a.isAudio) ...[
        _Row(
          icon: PhosphorIcons.arrowsOutSimple(),
          label: NotesStrings.sizeLabel,
          trailing: _Segmented<String>(
            value: size,
            options: const {
              's': NotesStrings.sizeSmall,
              'm': NotesStrings.sizeMedium,
              'full': NotesStrings.sizeFull,
            },
            onChanged: (v) => _run(() => a.onSetAttrs({imageSizeKey: v})),
          ),
        ),
        _Row(
          icon: PhosphorIcons.textAlignLeft(),
          label: NotesStrings.alignLabel,
          trailing: _Segmented<String>(
            value: align,
            options: const {
              'left': NotesStrings.alignLeft,
              'center': NotesStrings.alignCenter,
            },
            onChanged: (v) => _run(() => a.onSetAttrs({imageAlignKey: v})),
          ),
        ),
        _Row(
          icon: PhosphorIcons.textT(),
          label: NotesStrings.editCaption,
          onTap: () => _closeThen(a.onEditText),
        ),
        if (a.onReplace != null)
          _Row(
            icon: PhosphorIcons.swap(),
            label: NotesStrings.replaceImage,
            onTap: () => _closeThen(a.onReplace!),
          ),
      ] else ...[
        _Row(
          icon: PhosphorIcons.gauge(),
          label: NotesStrings.speedLabel,
          trailing: _Segmented<int>(
            value: speed,
            options: {for (final s in audioSpeeds) s: speedLabel(s)},
            onChanged: (v) => _run(() => a.onSetAttrs({audioSpeedKey: v})),
          ),
        ),
        _Row(
          icon: PhosphorIcons.pencilSimple(),
          label: NotesStrings.rename,
          onTap: () => _closeThen(a.onEditText),
        ),
        _Row(
          icon: PhosphorIcons.article(),
          label: NotesStrings.transcribe,
          onTap: a.onTranscribe == null
              ? null
              : () => _closeThen(a.onTranscribe!),
        ),
      ],
      _Row(
        icon: PhosphorIcons.shareNetwork(),
        label: NotesStrings.shareFile,
        onTap: () => _closeThen(a.onShare),
      ),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...rows,
            Divider(height: 16, color: lum.borderSubtle),
            _Row(
              icon: PhosphorIcons.trash(),
              label: NotesStrings.deleteMedia,
              destructive: true,
              onTap: () => _closeThen(a.onDelete),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final lum = context.lum;
    final disabled = onTap == null && trailing == null;
    final color = destructive
        ? lum.textDanger
        : disabled
            ? lum.textDisabled
            : lum.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(LumRadius.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(children: [
          Icon(icon, size: LumSize.iconSm, color: color),
          const SizedBox(width: LumSpace.md),
          Expanded(
            child: Text(
              label,
              style: LumText.body.copyWith(color: color),
            ),
          ),
          if (trailing != null) trailing!,
        ]),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final lum = context.lum;
    return IconButton(
      onPressed: onTap,
      tooltip: label,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      icon: Icon(
        icon,
        size: LumSize.iconSm,
        color: onTap == null ? lum.textDisabled : lum.textPrimary,
      ),
    );
  }
}

/// A 32 pt segmented control.
class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final lum = context.lum;
    return Container(
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: lum.bgSurfaceSunken,
        borderRadius: BorderRadius.circular(LumRadius.sm),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (final e in options.entries)
          Semantics(
            button: true,
            selected: e.key == value,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(e.key),
              child: AnimatedContainer(
                duration: LumMotion.fast,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: e.key == value ? lum.bgPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(LumRadius.sm - 2),
                ),
                child: Text(
                  e.value,
                  style: LumText.footnote.copyWith(
                    color:
                        e.key == value ? lum.textOnPrimary : lum.textSecondary,
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

enum InsertChoice { camera, photos, record, checklist }

/// The Insert popover opened from the editor toolbar.
Future<InsertChoice?> showInsertSheet(BuildContext context) {
  return showModalBottomSheet<InsertChoice>(
    useRootNavigator: true,
    context: context,
    showDragHandle: true,
    backgroundColor: context.lum.bgElevated,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _Row(
            icon: PhosphorIcons.camera(),
            label: NotesStrings.insertCamera,
            onTap: () => Navigator.pop(ctx, InsertChoice.camera),
          ),
          _Row(
            icon: PhosphorIcons.image(),
            label: NotesStrings.insertPhotos,
            onTap: () => Navigator.pop(ctx, InsertChoice.photos),
          ),
          _Row(
            icon: PhosphorIcons.microphone(),
            label: NotesStrings.insertRecord,
            onTap: () => Navigator.pop(ctx, InsertChoice.record),
          ),
          _Row(
            icon: PhosphorIcons.checkSquare(),
            label: NotesStrings.insertChecklist,
            onTap: () => Navigator.pop(ctx, InsertChoice.checklist),
          ),
        ]),
      ),
    ),
  );
}
