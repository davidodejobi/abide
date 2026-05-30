import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

String _format(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// Bottom sheet that records a voice note. Recording starts as soon as the
/// sheet opens; tapping the stop button pops the **temporary file path** of the
/// recording, which the caller persists via `FileStorageService`. Cancelling
/// (or dismissing) discards the take and pops `null`.
class AudioRecorderSheet extends HookWidget {
  const AudioRecorderSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final controller = useMemoized(RecorderController.new);
    useEffect(() => controller.dispose, [controller]);

    final path = useRef<String?>(null);
    final starting = useState(true);
    final error = useState<String?>(null);

    // Start recording as soon as the sheet opens. The `active` flag guards
    // against writing state if the sheet is dismissed mid-start.
    useEffect(() {
      var active = true;
      () async {
        try {
          final dir = await getTemporaryDirectory();
          final filePath = p.join(dir.path, '${_uuid.v4()}.m4a');
          await controller.record(path: filePath);
          if (!active) return;
          path.value = filePath;
          starting.value = false;
        } catch (_) {
          if (!active) return;
          error.value =
              'Microphone unavailable. Check permissions and try again.';
          starting.value = false;
        }
      }();
      return () => active = false;
    }, const []);

    Future<void> stopAndSave() async {
      final recorded = await controller.stop();
      if (!context.mounted) return;
      Navigator.of(context).pop(recorded ?? path.value);
    }

    Future<void> cancel() async {
      if (controller.isRecording) await controller.stop();
      final filePath = path.value;
      if (filePath != null) {
        final file = File(filePath);
        if (file.existsSync()) await file.delete();
      }
      if (!context.mounted) return;
      Navigator.of(context).pop();
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (error.value != null) ...[
              Text(
                error.value!,
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
                  (_) => controller.recordedDuration,
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
                recorderController: controller,
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
                    onPressed: cancel,
                    child: const Text('Cancel'),
                  ),
                  FilledButton.icon(
                    onPressed: starting.value ? null : stopAndSave,
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
