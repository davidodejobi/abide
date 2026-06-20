import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/utils/services/file_storage_service.dart';
import 'package:openbaptisthymnal/features/tablet/domain/tablet_media.dart';

/// Audio clips are persisted as ordinary `image` nodes whose url points at an
/// audio file (see [isAudioPath]). This builder intercepts the standard `image`
/// type: audio urls render as an inline player, everything else is delegated
/// back to appflowy's built-in [ImageBlockComponentBuilder] unchanged.
class MediaBlockComponentBuilder extends BlockComponentBuilder {
  MediaBlockComponentBuilder({
    required this.editorState,
    super.configuration,
  });

  // The editor owns its [EditorState]; we thread it in explicitly rather than
  // reading appflowy's internal `Provider<EditorState>`, so the notes feature
  // takes no direct dependency on package:provider.
  final EditorState editorState;

  final ImageBlockComponentBuilder _imageBuilder = ImageBlockComponentBuilder();

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    final url = node.attributes[ImageBlockKeys.url] as String? ?? '';
    if (isAudioPath(url)) {
      return AudioBlockComponentWidget(
        key: node.key,
        node: node,
        editorState: editorState,
        configuration: configuration,
        showActions: showActions(node),
        actionBuilder: (context, state) =>
            actionBuilder(blockComponentContext, state),
        actionTrailingBuilder: (context, state) =>
            actionTrailingBuilder(blockComponentContext, state),
      );
    }
    // Forward the renderer's wiring so delegated images keep their behavior.
    _imageBuilder
      ..configuration = configuration
      ..showActions = showActions
      ..actionBuilder = actionBuilder
      ..actionTrailingBuilder = actionTrailingBuilder;
    return _imageBuilder.build(blockComponentContext);
  }

  @override
  BlockComponentValidate get validate =>
      (node) => node.delta == null && node.children.isEmpty;
}

class AudioBlockComponentWidget extends BlockComponentStatefulWidget {
  const AudioBlockComponentWidget({
    super.key,
    required super.node,
    required this.editorState,
    super.showActions,
    super.actionBuilder,
    super.actionTrailingBuilder,
    super.configuration = const BlockComponentConfiguration(),
  });

  final EditorState editorState;

  @override
  State<AudioBlockComponentWidget> createState() =>
      _AudioBlockComponentWidgetState();
}

class _AudioBlockComponentWidgetState extends State<AudioBlockComponentWidget>
    with SelectableMixin, BlockComponentConfigurable {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  final _audioKey = GlobalKey();
  RenderBox? get _renderBox => context.findRenderObject() as RenderBox?;

  final _player = PlayerController();

  // `fitWidth` spans the container only when the extracted sample count equals
  // `width / spacing`, so the same spacing must drive both `getSamplesForWidth`
  // (at prepare time) and the rendered style (at build time).
  static const _waveSpacing = 5.0;

  PlayerWaveStyle _buildWaveStyle(ThemeData theme) => PlayerWaveStyle(
        spacing: _waveSpacing,
        showSeekLine: false,
        fixedWaveColor: theme.colorScheme.outlineVariant,
        liveWaveColor: theme.colorScheme.primary,
      );

  bool _prepared = false;

  /// Preparation is deferred until [LayoutBuilder] hands us the real waveform
  /// width: `WaveformType.fitWidth` only spans the container when the extracted
  /// sample count matches `width / spacing`. Preparing in `initState` (before
  /// layout) would fall back to the default 100 samples and render at a fixed
  /// width unrelated to the tile, which looked like a half-length waveform.
  bool _preparing = false;

  Future<void> _prepare(double width) async {
    if (_preparing || _prepared) return;
    _preparing = true;
    final url = node.attributes[ImageBlockKeys.url] as String? ?? '';
    try {
      await _player.preparePlayer(
        path: FileStorageService.absolutePath(url),
        shouldExtractWaveform: true,
        noOfSamples: width ~/ _waveSpacing,
      );
      if (mounted) setState(() => _prepared = true);
    } catch (_) {
      // Leave _prepared false; the tile shows a disabled control.
    } finally {
      _preparing = false;
    }
  }

  String _formatRemaining(int positionMs) {
    final total = _player.maxDuration;
    final remainingMs = total <= 0 ? 0 : (total - positionMs).clamp(0, total);
    final d = Duration(milliseconds: remainingMs);
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (!_prepared) return;
    if (_player.playerState.isPlaying) {
      await _player.pausePlayer();
    } else {
      await _player.startPlayer();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final editorState = widget.editorState;

    Widget child = Container(
      key: _audioKey,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          StreamBuilder<PlayerState>(
            stream: _player.onPlayerStateChanged,
            builder: (context, _) {
              final playing = _player.playerState.isPlaying;
              return IconButton(
                onPressed: _toggle,
                icon: Icon(
                  playing ? Icons.pause_circle : Icons.play_circle,
                  size: 36,
                  color: theme.colorScheme.primary,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // A finite width is required both to fit the waveform to the
                // tile and to make the seek gesture map taps correctly
                // (the package divides by `size.width`, so `infinity` breaks it).
                final width = constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : MediaQuery.of(context).size.width;
                if (!_prepared) _prepare(width);
                return _prepared
                    ? AudioFileWaveforms(
                        size: Size(width, 40),
                        playerController: _player,
                        enableSeekGesture: true,
                        waveformType: WaveformType.fitWidth,
                        playerWaveStyle: _buildWaveStyle(theme),
                      )
                    : SizedBox(
                        height: 40,
                        child: Center(
                          child: Text(
                            'Voice note',
                            style: TextStyle(
                              fontFamily: 'Geist',
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
              },
            ),
          ),
          const SizedBox(width: 8),
          // Time remaining counts down as the clip plays; shows total length
          // while paused/at-rest so the user knows the clip duration up front.
          StreamBuilder<int>(
            stream: _player.onCurrentDurationChanged,
            builder: (context, snapshot) => Text(
              _prepared ? _formatRemaining(snapshot.data ?? 0) : '--:--',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );

    child = Padding(padding: padding, child: child);

    child = BlockSelectionContainer(
      node: node,
      delegate: this,
      listenable: editorState.selectionNotifier,
      remoteSelection: editorState.remoteSelections,
      blockColor: editorState.editorStyle.selectionColor,
      supportTypes: const [BlockSelectionType.block],
      child: child,
    );

    if (widget.showActions && widget.actionBuilder != null) {
      child = BlockComponentActionWrapper(
        node: node,
        actionBuilder: widget.actionBuilder!,
        actionTrailingBuilder: widget.actionTrailingBuilder,
        child: child,
      );
    }

    return child;
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
    final box = _audioKey.currentContext?.findRenderObject();
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
