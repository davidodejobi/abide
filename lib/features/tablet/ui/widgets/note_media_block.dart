import 'dart:io';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/utils/services/file_storage_service.dart';
import 'package:openbaptisthymnal/features/tablet/domain/note_media.dart';
import 'package:openbaptisthymnal/features/tablet/domain/note_media_actions.dart';
import 'package:openbaptisthymnal/features/tablet/domain/parse_links.dart';
import 'package:openbaptisthymnal/features/tablet/ui/notes_strings.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/note_media_sheet.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/wikilink_spans.dart';

/// Renders the `image` and `audio` nodes of a note. Register one instance under
/// both [ImageBlockKeys.type] and [audioNodeType].
class NoteMediaBlockBuilder extends BlockComponentBuilder {
  NoteMediaBlockBuilder({
    required this.editorState,
    required this.storage,
    required this.onLink,
    super.configuration,
  });

  // The editor owns its [EditorState]; we thread it in explicitly rather than
  // reading appflowy's internal `Provider<EditorState>`.
  final EditorState editorState;
  final FileStorageService storage;

  /// Opens a `[[bible:...]]` / `[[hymn:...]]` link tapped in a caption.
  final void Function(ParsedLink link) onLink;

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return NoteMediaBlockWidget(
      key: node.key,
      node: node,
      editorState: editorState,
      storage: storage,
      onLink: onLink,
      configuration: configuration,
      showActions: false,
    );
  }

  @override
  BlockComponentValidate get validate =>
      (node) => node.delta == null && node.children.isEmpty;
}

class NoteMediaBlockWidget extends BlockComponentStatefulWidget {
  const NoteMediaBlockWidget({
    super.key,
    required super.node,
    required this.editorState,
    required this.storage,
    required this.onLink,
    super.showActions,
    super.configuration = const BlockComponentConfiguration(),
  });

  final EditorState editorState;
  final FileStorageService storage;
  final void Function(ParsedLink link) onLink;

  @override
  State<NoteMediaBlockWidget> createState() => _NoteMediaBlockState();
}

class _NoteMediaBlockState extends State<NoteMediaBlockWidget>
    with SelectableMixin, BlockComponentConfigurable {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  late final _actions = NoteMediaActions(widget.editorState);
  final _blockKey = GlobalKey();
  RenderBox? get _renderBox => context.findRenderObject() as RenderBox?;

  bool get _isAudio => node.type == audioNodeType;
  String get _url => node.attributes[mediaUrlKey] as String? ?? '';
  String get _text => node.attributes[mediaTextKey] as String? ?? '';
  bool get _missing => !isExternalUrl(_url) && !File(_url).existsSync();

  // Drag-to-reorder state. The block is lifted in place and committed on drop.
  double _dragDy = 0;
  int? _dropIndex;
  OverlayEntry? _dropLine;

  @override
  void dispose() {
    _dropLine?.remove();
    super.dispose();
  }

  // ---- actions ------------------------------------------------------------

  Future<void> _remove() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final removed = await _actions.remove(node);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: const Text(NotesStrings.mediaDeleted),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: NotesStrings.undo,
          onPressed: () => _actions.restore(removed),
        ),
      ));
  }

  Future<void> _editText() async {
    final controller = TextEditingController(text: _text);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isAudio ? NotesStrings.rename : NotesStrings.editCaption),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: _isAudio ? 1 : 3,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: _isAudio
                ? NotesStrings.recordingName
                : NotesStrings.captionHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(NotesStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text(NotesStrings.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;
    await _actions.setAttrs(node, {mediaTextKey: result});
  }

  Future<void> _replace() async {
    final rel = await widget.storage.pickAndPersistImage(bucket: 'note_images');
    if (rel == null) return;
    await _actions
        .setAttrs(node, {mediaUrlKey: FileStorageService.absolutePath(rel)});
  }

  Future<void> _share() async {
    final box = _renderBox;
    final origin =
        box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    await SharePlus.instance.share(ShareParams(
      files: [XFile(_url)],
      sharePositionOrigin: origin,
    ));
  }

  Future<void> _openSheet() {
    return showNoteMediaSheet(
      context,
      NoteMediaSheetActions(
        isAudio: _isAudio,
        attrs: () => node.attributes,
        canMoveUp: () => _actions.canMoveUp(node),
        canMoveDown: () => _actions.canMoveDown(node),
        onMoveUp: () => _actions.moveUp(node),
        onMoveDown: () => _actions.moveDown(node),
        onSetAttrs: (a) => _actions.setAttrs(node, a),
        onEditText: _editText,
        onShare: _share,
        onDelete: _remove,
        onReplace: _isAudio ? null : _replace,
      ),
    );
  }

  // ---- drag to reorder ----------------------------------------------------

  void _dragStart(DragStartDetails d) {
    HapticFeedback.mediumImpact();
    setState(() => _dragDy = 0);
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    _dropLine = OverlayEntry(builder: (_) => _DropLine(rect: _dropLineRect()));
    overlay?.insert(_dropLine!);
  }

  /// Sibling indices (excluding this block) with their global rects.
  List<Rect> _siblingRects() {
    final siblings = node.parent?.children ?? const <Node>[];
    return [
      for (final s in siblings)
        if (s != node && s.renderBox != null)
          s.renderBox!.localToGlobal(Offset.zero) & s.renderBox!.size,
    ];
  }

  Rect _myRect() {
    final box = _renderBox!;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  int _targetIndex() {
    final mine = _myRect().translate(0, _dragDy);
    var index = 0;
    for (final r in _siblingRects()) {
      if (r.center.dy < mine.center.dy) index++;
    }
    return index;
  }

  Rect _dropLineRect() {
    final rects = _siblingRects();
    final me = _myRect();
    if (rects.isEmpty) return Rect.fromLTWH(me.left, me.top, me.width, 0);
    final i = (_dropIndex ?? _targetIndex()).clamp(0, rects.length);
    final y = i >= rects.length ? rects.last.bottom : rects[i].top;
    return Rect.fromLTWH(me.left, y, me.width, 0);
  }

  void _dragUpdate(DragUpdateDetails d) {
    final target = _targetIndex();
    if (target != _dropIndex) HapticFeedback.selectionClick();
    setState(() {
      _dragDy += d.delta.dy;
      _dropIndex = target;
    });
    _dropLine?.markNeedsBuild();
    widget.editorState.autoScroller?.startAutoScrollIfNecessary(
      Rect.fromLTWH(d.globalPosition.dx, d.globalPosition.dy, 1, 1),
    );
  }

  Future<void> _dragEnd([DragEndDetails? _]) async {
    widget.editorState.autoScroller?.stopAutoScroll();
    _dropLine?.remove();
    _dropLine = null;
    final target = _dropIndex ?? node.path.last;
    setState(() {
      _dragDy = 0;
      _dropIndex = null;
    });
    await _actions.moveTo(node, target);
  }

  // ---- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final lum = context.lum;
    final editorState = widget.editorState;

    Widget child = ValueListenableBuilder<Selection?>(
      valueListenable: editorState.selectionNotifier,
      builder: (context, selection, _) {
        final selected = selection != null &&
            listEquals(selection.start.path, node.path) &&
            listEquals(selection.end.path, node.path);
        final dragging = _dragDy != 0 || _dropLine != null;
        final controls = _Controls(
          selected: selected,
          onMore: _openSheet,
          onDragStart: _dragStart,
          onDragUpdate: _dragUpdate,
          onDragEnd: _dragEnd,
        );
        final body = _missing
            ? _BrokenCard(onRemove: _remove, controls: controls)
            : _isAudio
                ? _AudioBody(
                    key: ValueKey('${node.id}-$_url'),
                    node: node,
                    actions: _actions,
                    selected: selected,
                    controls: controls,
                  )
                : _ImageBody(
                    node: node,
                    selected: selected,
                    controls: controls,
                    onLink: widget.onLink,
                    onEditCaption: _editText,
                    onBroken: () => setState(() {}),
                  );
        return GestureDetector(
          onLongPress: _openSheet,
          child: Transform.translate(
            offset: Offset(0, _dragDy),
            child: Transform.scale(
              scale: dragging ? 1.02 : 1,
              child: Material(
                color: Colors.transparent,
                elevation: dragging ? 8 : 0,
                shadowColor: lum.textPrimary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(LumRadius.md),
                child: body,
              ),
            ),
          ),
        );
      },
    );

    child = Padding(
      key: _blockKey,
      padding: padding.add(const EdgeInsets.symmetric(vertical: 6)),
      child: child,
    );

    return BlockSelectionContainer(
      node: node,
      delegate: this,
      listenable: editorState.selectionNotifier,
      remoteSelection: editorState.remoteSelections,
      blockColor: Colors.transparent,
      supportTypes: const [BlockSelectionType.block],
      child: child,
    );
  }

  @override
  Position start() => Position(path: widget.node.path, offset: 0);

  @override
  Position end() => Position(path: widget.node.path, offset: 1);

  @override
  Position getPositionInOffset(Offset start) => end();

  @override
  bool get shouldCursorBlink => false;

  @override
  CursorStyle get cursorStyle => CursorStyle.cover;

  @override
  Rect getBlockRect({bool shiftWithBaseOffset = false}) {
    final box = _blockKey.currentContext?.findRenderObject();
    if (box is RenderBox) return Offset.zero & box.size;
    return Rect.zero;
  }

  @override
  Rect? getCursorRectInPosition(
    Position position, {
    bool shiftWithBaseOffset = false,
  }) {
    if (_renderBox == null) return null;
    final size = _renderBox!.size;
    return Rect.fromLTWH(-size.width / 2.0, 0, size.width, size.height);
  }

  @override
  List<Rect> getRectsInSelection(
    Selection selection, {
    bool shiftWithBaseOffset = false,
  }) {
    if (_renderBox == null) return [];
    return [Offset.zero & _renderBox!.size];
  }

  @override
  Selection getSelectionInRange(Offset start, Offset end) => Selection.single(
        path: widget.node.path,
        startOffset: 0,
        endOffset: 1,
      );

  @override
  Offset localToGlobal(Offset offset, {bool shiftWithBaseOffset = false}) =>
      _renderBox!.localToGlobal(offset);
}

/// The ••• button, and while the block is selected a drag handle. Both live
/// inside the block on the right, away from the iOS left-edge back swipe.
class _Controls extends StatelessWidget {
  const _Controls({
    required this.selected,
    required this.onMore,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final bool selected;
  final VoidCallback onMore;
  final GestureDragStartCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    final lum = context.lum;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (selected)
        Semantics(
          label: NotesStrings.mediaDragHandle,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragStart: onDragStart,
            onVerticalDragUpdate: onDragUpdate,
            onVerticalDragEnd: onDragEnd,
            child: SizedBox(
              width: 36,
              height: 44,
              child: Icon(
                PhosphorIcons.dotsSixVertical(PhosphorIconsStyle.bold),
                size: LumSize.iconSm,
                color: lum.textSecondary,
              ),
            ),
          ),
        ),
      IconButton(
        onPressed: onMore,
        tooltip: NotesStrings.mediaMore,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        padding: EdgeInsets.zero,
        icon: Icon(
          PhosphorIcons.dotsThree(PhosphorIconsStyle.bold),
          size: LumSize.iconMd,
          color: lum.textSecondary,
        ),
      ),
    ]);
  }
}

class _DropLine extends StatelessWidget {
  const _DropLine({required this.rect});
  final Rect rect;

  @override
  Widget build(BuildContext context) {
    final lum = context.lum;
    return Positioned(
      left: rect.left,
      top: rect.top - 1,
      width: rect.width,
      child: IgnorePointer(
        child: Container(
          height: 3,
          decoration: BoxDecoration(
            color: lum.textAccent,
            borderRadius: BorderRadius.circular(2),
          ),
          alignment: Alignment.centerRight,
          child: Semantics(
            label: NotesStrings.mediaDropHere,
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class _BrokenCard extends StatelessWidget {
  const _BrokenCard({required this.onRemove, required this.controls});
  final VoidCallback onRemove;
  final Widget controls;

  @override
  Widget build(BuildContext context) {
    final lum = context.lum;
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: lum.bgSurfaceSunken,
        borderRadius: BorderRadius.circular(LumRadius.md),
        border: Border.all(color: lum.borderSubtle),
      ),
      child: Row(children: [
        Icon(PhosphorIcons.warningCircle(), color: lum.textSecondary),
        const SizedBox(width: LumSpace.sm),
        Expanded(
          child: Text(
            NotesStrings.fileMissing,
            style: LumText.subheadline.copyWith(color: lum.textSecondary),
          ),
        ),
        TextButton(
          onPressed: onRemove,
          style: TextButton.styleFrom(foregroundColor: lum.textDanger),
          child: const Text(NotesStrings.remove),
        ),
        controls,
      ]),
    );
  }
}

// ---- image ----------------------------------------------------------------

class _ImageBody extends StatelessWidget {
  const _ImageBody({
    required this.node,
    required this.selected,
    required this.controls,
    required this.onLink,
    required this.onEditCaption,
    required this.onBroken,
  });

  final Node node;
  final bool selected;
  final Widget controls;
  final void Function(ParsedLink) onLink;
  final VoidCallback onEditCaption;
  final VoidCallback onBroken;

  @override
  Widget build(BuildContext context) {
    final lum = context.lum;
    final a = node.attributes;
    final url = a[mediaUrlKey] as String? ?? '';
    final caption = a[mediaTextKey] as String? ?? '';
    final size = a[imageSizeKey] as String? ?? defaultImageSize;
    final left = (a[imageAlignKey] as String? ?? defaultImageAlign) == 'left';
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return LayoutBuilder(builder: (context, cons) {
      final width = cons.maxWidth * imageSizeFraction(size);
      Widget image(ImageProvider provider) => Image(
            image: ResizeImage.resizeIfNeeded(
                (width * dpr).round(), null, provider),
            width: width,
            fit: BoxFit.fitWidth,
            errorBuilder: (_, __, ___) => SizedBox(
              width: width,
              child: _BrokenCard(onRemove: () {}, controls: controls),
            ),
          );
      return Align(
        alignment: left ? Alignment.centerLeft : Alignment.center,
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment:
                left ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Stack(children: [
                Container(
                  // Keeps the controls reachable while the image decodes.
                  constraints: const BoxConstraints(minHeight: 56),
                  foregroundDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(LumRadius.md),
                    border: selected
                        ? Border.all(color: lum.textAccent, width: 2)
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(LumRadius.md),
                    child: image(isExternalUrl(url)
                        ? NetworkImage(url) as ImageProvider
                        : FileImage(File(url))),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: lum.bgElevated.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(LumRadius.full),
                    ),
                    child: controls,
                  ),
                ),
              ]),
              if (caption.isNotEmpty)
                _Caption(text: caption, onLink: onLink, left: left)
              else if (selected)
                TextButton(
                  onPressed: onEditCaption,
                  child: Text(
                    NotesStrings.addCaption,
                    style: LumText.footnote.copyWith(color: lum.textSecondary),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

/// Caption under an image. `[[bible:...]]` and `[[hymn:...]]` tokens in it are
/// tappable, exactly like in the note body.
class _Caption extends StatefulWidget {
  const _Caption(
      {required this.text, required this.onLink, required this.left});
  final String text;
  final void Function(ParsedLink) onLink;
  final bool left;

  @override
  State<_Caption> createState() => _CaptionState();
}

class _CaptionState extends State<_Caption> {
  final _recognizers = <TapGestureRecognizer>[];

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final style = LumText.footnote.copyWith(color: context.lum.textSecondary);
    final spans = wikilinkSpans(
      context,
      widget.text,
      style,
      widget.onLink,
      recognizers: _recognizers,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text.rich(
        TextSpan(
          style: style,
          children: spans.isEmpty ? [TextSpan(text: widget.text)] : spans,
        ),
        textAlign: widget.left ? TextAlign.start : TextAlign.center,
      ),
    );
  }
}

// ---- audio ----------------------------------------------------------------

String _clock(int ms) {
  final d = Duration(milliseconds: ms < 0 ? 0 : ms);
  final m = d.inMinutes.toString();
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// Compact (64 to 72 pt) recording row: play, name over stored-peaks waveform,
/// elapsed / total, speed chip and the block controls. The native player is
/// only created on the first Play tap.
class _AudioBody extends StatefulWidget {
  const _AudioBody({
    super.key,
    required this.node,
    required this.actions,
    required this.selected,
    required this.controls,
  });

  final Node node;
  final NoteMediaActions actions;
  final bool selected;
  final Widget controls;

  @override
  State<_AudioBody> createState() => _AudioBodyState();
}

class _AudioBodyState extends State<_AudioBody> {
  PlayerController? _player;
  bool _prepared = false;
  bool _busy = false;

  Map<String, dynamic> get _a => widget.node.attributes;
  String get _url => _a[mediaUrlKey] as String? ?? '';
  int get _speed => _a[audioSpeedKey] as int? ?? 100;
  int get _durationMs => _a[audioDurationKey] as int? ?? 0;

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    final player = _player ??= PlayerController();
    await player.preparePlayer(path: _url, shouldExtractWaveform: false);
    _prepared = true;
    // Clips recorded before peaks were stored get them once, on first play.
    final peaks = _a[audioPeaksKey] as String? ?? '';
    if (peaks.isEmpty || _durationMs == 0) {
      final samples = peaks.isEmpty
          ? await player.extractWaveformData(path: _url, noOfSamples: peakBars)
          : const <double>[];
      await widget.actions.setAttrsQuietly(widget.node, {
        if (peaks.isEmpty) audioPeaksKey: encodePeaks(samples),
        if (_durationMs == 0) audioDurationKey: player.maxDuration,
      });
    }
  }

  Future<void> _toggle() async {
    if (_busy) return;
    _busy = true;
    try {
      if (!_prepared) await _prepare();
      final player = _player!;
      if (player.playerState.isPlaying) {
        await player.pausePlayer();
      } else {
        await player.startPlayer();
        await player.setRate(_speed / 100);
        // Finished clips need preparing again before the next play.
        player.onCompletion.first.then((_) {
          _prepared = false;
          if (mounted) setState(() {});
        });
      }
    } catch (_) {
      // Unplayable file: the block simply stays at rest.
    } finally {
      _busy = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _cycleSpeed() async {
    final next =
        audioSpeeds[(audioSpeeds.indexOf(_speed) + 1) % audioSpeeds.length];
    await widget.actions.setAttrs(widget.node, {audioSpeedKey: next});
    if (_prepared) await _player?.setRate(next / 100);
    if (mounted) setState(() {});
  }

  Future<void> _seekFraction(double f) async {
    final player = _player;
    if (player == null || !_prepared) return;
    await player.seekTo((player.maxDuration * f.clamp(0, 1)).round());
  }

  @override
  Widget build(BuildContext context) {
    final lum = context.lum;
    final bars = decodePeaks(_a[audioPeaksKey] as String? ?? '');
    final name = (_a[mediaTextKey] as String? ?? '').trim();
    final total = _durationMs > 0 ? _durationMs : (_player?.maxDuration ?? 0);

    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: lum.bgGroupedCell,
        borderRadius: BorderRadius.circular(LumRadius.md),
        border: widget.selected
            ? Border.all(color: lum.textAccent, width: 2)
            : Border.all(color: lum.borderSubtle),
      ),
      child: Row(children: [
        StreamBuilder<PlayerState>(
          stream: _player?.onPlayerStateChanged,
          builder: (context, _) {
            final playing = _player?.playerState.isPlaying ?? false;
            return IconButton(
              onPressed: _toggle,
              tooltip: playing ? NotesStrings.pause : NotesStrings.play,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              padding: EdgeInsets.zero,
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: lum.bgPrimary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  playing
                      ? PhosphorIcons.pause(PhosphorIconsStyle.fill)
                      : PhosphorIcons.play(PhosphorIconsStyle.fill),
                  size: 18,
                  color: lum.textOnPrimary,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: LumSpace.sm),
        Expanded(
          child: StreamBuilder<int>(
            stream: _player?.onCurrentDurationChanged,
            builder: (context, snap) {
              final pos = snap.data ?? 0;
              final progress = total > 0 ? (pos / total).clamp(0.0, 1.0) : 0.0;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? NotesStrings.audioTitle : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LumText.subheadlineEmphasized
                        .copyWith(color: lum.textPrimary, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  LayoutBuilder(
                    builder: (context, c) => GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (d) =>
                          _seekFraction(d.localPosition.dx / c.maxWidth),
                      onHorizontalDragUpdate: (d) =>
                          _seekFraction(d.localPosition.dx / c.maxWidth),
                      child: CustomPaint(
                        size: Size(c.maxWidth, 20),
                        painter: _PeaksPainter(
                          bars: bars,
                          progress: progress,
                          played: lum.textAccent,
                          rest: lum.borderSubtle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    total > 0 ? '${_clock(pos)} / ${_clock(total)}' : '--:--',
                    style: LumText.footnote.copyWith(
                      fontSize: 13,
                      color: lum.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        // 52 x 32 visible chip with a 56 x 44 hit area.
        Semantics(
          button: true,
          label: '${NotesStrings.speedLabel} ${speedLabel(_speed)}',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _cycleSpeed,
            child: SizedBox(
              width: 56,
              height: 44,
              child: Center(
                child: Container(
                  width: 52,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: lum.bgSurfaceSunken,
                    borderRadius: BorderRadius.circular(LumRadius.full),
                  ),
                  child: Text(
                    speedLabel(_speed),
                    style: LumText.footnote
                        .copyWith(color: lum.textPrimary, fontSize: 13),
                  ),
                ),
              ),
            ),
          ),
        ),
        widget.controls,
      ]),
    );
  }
}

/// Draws the stored peaks, coloured played vs not yet played. Clips with no
/// stored peaks yet show a flat row of low bars.
class _PeaksPainter extends CustomPainter {
  _PeaksPainter({
    required this.bars,
    required this.progress,
    required this.played,
    required this.rest,
  });

  final List<double> bars;
  final double progress;
  final Color played;
  final Color rest;

  @override
  void paint(Canvas canvas, Size size) {
    final data = bars.isEmpty ? List.filled(peakBars, 0.25) : bars;
    final n = data.length;
    final slot = size.width / n;
    final w = (slot * 0.55).clamp(1.5, 4.0);
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w;
    for (var i = 0; i < n; i++) {
      final h = (data[i].clamp(0.08, 1.0)) * size.height;
      final x = slot * i + slot / 2;
      paint.color = (i + 0.5) / n <= progress ? played : rest;
      canvas.drawLine(
        Offset(x, (size.height - h) / 2),
        Offset(x, (size.height + h) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PeaksPainter old) =>
      old.progress != progress || old.bars != bars || old.played != played;
}
