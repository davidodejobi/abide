import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Bottom sheet that records a voice note. Recording starts as soon as the
/// sheet opens; tapping the stop button pops the **temporary file path** of the
/// recording, which the caller persists via `FileStorageService`. Cancelling
/// (or dismissing) discards the take and pops `null`.
class AudioRecorderSheet extends StatefulWidget {
  const AudioRecorderSheet({super.key});

  @override
  State<AudioRecorderSheet> createState() => _AudioRecorderSheetState();
}

class _AudioRecorderSheetState extends State<AudioRecorderSheet> {
  static const _uuid = Uuid();

  final _controller = RecorderController();
  String? _path;
  bool _starting = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final dir = await getTemporaryDirectory();
      final path = p.join(dir.path, '${_uuid.v4()}.m4a');
      await _controller.record(path: path);
      if (!mounted) return;
      setState(() {
        _path = path;
        _starting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Microphone unavailable. Check permissions and try again.';
        _starting = false;
      });
    }
  }

  Future<void> _stopAndSave() async {
    final path = await _controller.stop();
    if (!mounted) return;
    Navigator.of(context).pop(path ?? _path);
  }

  Future<void> _cancel() async {
    if (_controller.isRecording) {
      await _controller.stop();
    }
    final path = _path;
    if (path != null) {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null) ...[
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ] else ...[
              StreamBuilder<Duration>(
                stream: Stream.periodic(
                  const Duration(milliseconds: 200),
                  (_) => _controller.recordedDuration,
                ),
                builder: (context, snapshot) => Text(
                  _format(snapshot.data ?? Duration.zero),
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AudioWaveforms(
                recorderController: _controller,
                size: Size(MediaQuery.of(context).size.width - 40, 64),
                waveStyle: WaveStyle(
                  waveColor: theme.colorScheme.primary,
                  extendWaveform: true,
                  showMiddleLine: false,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: _cancel,
                    child: const Text('Cancel'),
                  ),
                  FilledButton.icon(
                    onPressed: _starting ? null : _stopAndSave,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop & insert'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
