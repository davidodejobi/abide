import 'dart:io';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:auto_route/auto_route.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/audio/audio_quality_provider.dart';
import 'package:openbaptisthymnal/core/providers/service_providers.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/utils/services/file_storage_service.dart';
import 'package:openbaptisthymnal/core/widgets/lum_button.dart';
import 'package:openbaptisthymnal/core/widgets/lum_circle_button.dart';
import 'package:openbaptisthymnal/core/widgets/lum_page_background.dart';
import 'package:openbaptisthymnal/features/tablet/domain/note_media.dart';
import 'package:openbaptisthymnal/features/tablet/domain/recording_note.dart';
import 'package:openbaptisthymnal/features/tablet/domain/tablet_markdown_codec.dart';
import 'package:openbaptisthymnal/features/tablet/providers/tablets_providers.dart';
import 'package:openbaptisthymnal/features/tablet/providers/recording_providers.dart';
import 'package:openbaptisthymnal/features/tablet/ui/notes_strings.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// A finished take: the **temporary file path** (the caller moves it into
/// storage), its length, the waveform bars captured while recording and the
/// markers the user dropped.
class RecordingResult {
  const RecordingResult({
    required this.path,
    required this.durationMs,
    required this.peaks,
    required this.markers,
    required this.name,
  });
  final String path;
  final int durationMs;
  final String peaks;
  final List<RecordingMarker> markers;
  final String name;
}

/// Opens the full-screen recorder. Null when cancelled or discarded.
Future<RecordingResult?> openRecorder(BuildContext context) =>
    Navigator.of(context, rootNavigator: true).push<RecordingResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const RecordingPage(),
      ),
    );

/// Moves the take into storage and returns the note blocks for it: the audio
/// block, then one paragraph per marker.
Future<List<Node>> persistRecording(WidgetRef ref, RecordingResult r) async {
  final relative = await ref
      .read(fileStorageServiceProvider)
      .persistFile(r.path, bucket: 'note_audio', move: true);
  return recordingNodes(
    url: FileStorageService.absolutePath(relative),
    name: r.name,
    durationMs: r.durationMs,
    peaks: r.peaks,
    markers: r.markers,
  );
}

/// Notes tab entry: record, then open a new note titled after the take.
Future<void> recordMessageNote(BuildContext context, WidgetRef ref) async {
  final result = await openRecorder(context);
  if (result == null || !context.mounted) return;
  final nodes = await persistRecording(ref, result);
  final id = await ref.read(tabletsRepositoryProvider).createNote(
        title: result.name,
        contentMarkdown: noteDocumentToMarkdown(
            Document(root: pageNode(children: nodes))),
      );
  if (!context.mounted) return;
  await context.router.push(TabletEditorRoute(noteId: id));
}

enum _Phase { consent, starting, recording, paused, interrupted, denied, error }

/// Record a message (recording_1): 44 pt timer, 72 pt Pause, live waveform,
/// markers. Foreground only: the screen is kept awake and the take pauses if
/// the app leaves the foreground.
class RecordingPage extends HookConsumerWidget {
  const RecordingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lum = context.lum;
    final quality = ref.watch(audioQualityProvider);
    final controller = useMemoized(
      () => RecorderController()
        // An explicit AAC profile: the native default is a muffled ~32 kbps.
        ..androidEncoder = AndroidEncoder.aac
        ..androidOutputFormat = AndroidOutputFormat.mpeg4
        ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
        ..sampleRate = quality.sampleRate
        ..bitRate = quality.bitRate,
      [quality],
    );
    useEffect(() => controller.dispose, [controller]);

    final phase = useState(
      ref.read(recordingConsentProvider) ? _Phase.starting : _Phase.consent,
    );
    final markers = useState(<RecordingMarker>[]);
    final labelling = useState<int?>(null); // index of the marker being named
    final labelController = useTextEditingController();
    final path = useRef<String?>(null);
    final elapsed = useRef(Duration.zero);
    final startedAt = useMemoized(DateTime.now);

    useEffect(() {
      final sub = controller.onCurrentDuration.listen((d) => elapsed.value = d);
      return sub.cancel;
    }, [controller]);

    // Screen stays on for the whole take.
    useEffect(() {
      WakelockPlus.enable();
      return () {
        WakelockPlus.disable();
      };
    }, const []);

    Future<void> start() async {
      phase.value = _Phase.starting;
      try {
        if (!await controller.checkPermission()) {
          phase.value = _Phase.denied;
          return;
        }
        // ponytail: no free-space check, dart:io has no API for it and a
        // package just for this is not worth it; add one if low-storage
        // failures show up in the field.
        final dir = await getTemporaryDirectory();
        final filePath = p.join(dir.path, '${const Uuid().v4()}.m4a');
        await controller.record(path: filePath);
        path.value = filePath;
        phase.value = _Phase.recording;
      } catch (_) {
        phase.value = _Phase.error;
      }
    }

    useEffect(() {
      if (phase.value == _Phase.starting) start();
      return null;
    }, const []);

    // No interruption hook in audio_waveforms: a call, Siri or leaving the app
    // all move the app out of `resumed`, so pause there.
    useOnAppLifecycleStateChange((_, state) async {
      if (phase.value != _Phase.recording) return;
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive) {
        phase.value = _Phase.interrupted;
        try {
          await controller.pause();
        } catch (_) {}
      }
    });

    Future<void> pauseOrResume() async {
      try {
        if (phase.value == _Phase.recording) {
          await controller.pause();
          phase.value = _Phase.paused;
        } else {
          await controller.record();
          phase.value = _Phase.recording;
        }
      } catch (_) {
        phase.value = _Phase.error;
      }
    }

    Future<void> discard() async {
      try {
        await controller.stop();
      } catch (_) {}
      final f = path.value;
      if (f != null && File(f).existsSync()) await File(f).delete();
      if (context.mounted) Navigator.of(context).pop();
    }

    Future<void> finish() async {
      final peaks = encodePeaks(List<double>.of(controller.waveData));
      final ms = elapsed.value.inMilliseconds;
      final stopped = await controller.stop();
      final f = stopped ?? path.value;
      if (!context.mounted) return;
      Navigator.of(context).pop(
        f == null
            ? null
            : RecordingResult(
                path: f,
                durationMs: ms,
                peaks: peaks,
                markers: markers.value,
                name: defaultRecordingName(startedAt),
              ),
      );
    }

    Future<void> close() async {
      final live = phase.value == _Phase.recording ||
          phase.value == _Phase.paused ||
          phase.value == _Phase.interrupted;
      if (!live) return Navigator.of(context).pop();
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(NotesStrings.saveRecordingTitle),
          content: const Text(NotesStrings.saveRecordingBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'keep'),
              child: const Text(NotesStrings.keepRecording),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'discard'),
              child: const Text(NotesStrings.discard),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'save'),
              child: const Text(NotesStrings.save),
            ),
          ],
        ),
      );
      if (choice == 'save') await finish();
      if (choice == 'discard') await discard();
    }

    void addMarker() {
      markers.value = [
        ...markers.value,
        RecordingMarker(elapsed.value.inMilliseconds),
      ];
      labelController.clear();
      labelling.value = markers.value.length - 1;
    }

    void commitLabel({required bool keep}) {
      final i = labelling.value;
      if (i != null && keep) {
        final next = [...markers.value];
        next[i] = next[i].withLabel(labelController.text);
        markers.value = next;
      }
      labelling.value = null;
    }

    final live = phase.value == _Phase.recording ||
        phase.value == _Phase.paused ||
        phase.value == _Phase.interrupted;

    Widget body;
    switch (phase.value) {
      case _Phase.consent:
        body = _Consent(
          onAccept: () async {
            await ref.read(recordingConsentProvider.notifier).accept();
            await start();
          },
          onNotNow: () => Navigator.of(context).pop(),
        );
      case _Phase.denied:
        body = _Notice(
          title: NotesStrings.micOffTitle,
          body: NotesStrings.micOffBody,
          action: NotesStrings.openSettings,
          // ponytail: iOS-only deep link (`app-settings:`); Android users get
          // the text. A settings package is not worth it for one button.
          onAction: () => launchUrl(Uri.parse('app-settings:')),
        );
      case _Phase.error:
        body = const _Notice(title: NotesStrings.micError, body: '');
      default:
        body = _Recorder(
          controller: controller,
          phase: phase.value,
          markers: markers.value,
          labelling: labelling.value,
          labelController: labelController,
          onPause: pauseOrResume,
          onMarker: live ? addMarker : null,
          onFinish: live ? finish : null,
          onLabel: commitLabel,
        );
    }

    return PopScope(
      canPop: !live,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) close();
      },
      child: LumPageBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: LumSpace.md),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: LumCircleButton(
                          icon: PhosphorIcons.x(),
                          label: NotesStrings.cancel,
                          onPressed: close,
                        ),
                      ),
                      Text(
                        NotesStrings.recordTitle,
                        style: LumText.subheadlineEmphasized
                            .copyWith(color: lum.textPrimary),
                      ),
                    ],
                  ),
                  Expanded(child: body),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Recorder extends StatelessWidget {
  const _Recorder({
    required this.controller,
    required this.phase,
    required this.markers,
    required this.labelling,
    required this.labelController,
    required this.onPause,
    required this.onMarker,
    required this.onFinish,
    required this.onLabel,
  });

  final RecorderController controller;
  final _Phase phase;
  final List<RecordingMarker> markers;
  final int? labelling;
  final TextEditingController labelController;
  final VoidCallback onPause;
  final VoidCallback? onMarker;
  final VoidCallback? onFinish;
  final void Function({required bool keep}) onLabel;

  @override
  Widget build(BuildContext context) {
    final lum = context.lum;
    final running = phase == _Phase.recording;
    final status = switch (phase) {
      _Phase.recording => NotesStrings.recordingNow,
      _Phase.paused => NotesStrings.recordingPaused,
      _Phase.interrupted => NotesStrings.recordingInterrupted,
      _ => '',
    };
    return Column(
      children: [
        const SizedBox(height: LumSpace.lg),
        Text(status,
            style: LumText.footnote.copyWith(color: lum.textSecondary)),
        const SizedBox(height: LumSpace.sm),
        StreamBuilder<Duration>(
          // `onCurrentDuration` emits the running elapsed time while recording.
          stream: controller.onCurrentDuration,
          builder: (context, snap) => Semantics(
            liveRegion: false,
            child: Text(
              formatClock((snap.data ?? Duration.zero).inMilliseconds),
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 44,
                fontWeight: FontWeight.w700,
                color: lum.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        const SizedBox(height: LumSpace.lg),
        AudioWaveforms(
          recorderController: controller,
          size: Size(MediaQuery.of(context).size.width - 48, 64),
          waveStyle: WaveStyle(
            waveColor: lum.textAccent,
            extendWaveform: true,
            showMiddleLine: false,
          ),
        ),
        const SizedBox(height: LumSpace.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '${NotesStrings.markers} (${markers.length})',
            style: LumText.subheadlineEmphasized
                .copyWith(color: lum.textPrimary),
          ),
        ),
        const SizedBox(height: LumSpace.sm),
        Expanded(
          child: ListView(
            children: [
              for (var i = 0; i < markers.length; i++)
                if (i == labelling)
                  _LabelCard(
                    ms: markers[i].ms,
                    controller: labelController,
                    onDone: onLabel,
                  )
                else
                  _MarkerRow(marker: markers[i]),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SideButton(
              icon: PhosphorIcons.bookmarkSimple(),
              label: NotesStrings.addMarker,
              onTap: onMarker,
            ),
            Column(children: [
              Semantics(
                button: true,
                label: running ? NotesStrings.pause : NotesStrings.resume,
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: phase == _Phase.starting ? null : onPause,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: lum.bgPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      running
                          ? PhosphorIcons.pause(PhosphorIconsStyle.fill)
                          : PhosphorIcons.play(PhosphorIconsStyle.fill),
                      size: 32,
                      color: lum.textOnPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(running ? NotesStrings.pause : NotesStrings.resume,
                  style: LumText.footnote.copyWith(color: lum.textPrimary)),
            ]),
            _SideButton(
              icon: PhosphorIcons.check(),
              label: NotesStrings.finish,
              onTap: onFinish,
            ),
          ],
        ),
        const SizedBox(height: LumSpace.lg),
        Text(
          '${NotesStrings.keepOpen} ${NotesStrings.screenStaysOn}',
          textAlign: TextAlign.center,
          style: LumText.footnote.copyWith(color: lum.textSecondary),
        ),
        const SizedBox(height: LumSpace.lg),
      ],
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final lum = context.lum;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.4 : 1,
          child: Column(children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: lum.bgGroupedCell,
                borderRadius: BorderRadius.circular(LumRadius.md),
                border: Border.all(color: lum.borderSubtle),
              ),
              child: Icon(icon, color: lum.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(label,
                style: LumText.footnote.copyWith(color: lum.textPrimary)),
          ]),
        ),
      ),
    );
  }
}

class _MarkerRow extends StatelessWidget {
  const _MarkerRow({required this.marker});
  final RecordingMarker marker;

  @override
  Widget build(BuildContext context) {
    final lum = context.lum;
    return Container(
      margin: const EdgeInsets.only(bottom: LumSpace.sm),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: lum.bgGroupedCell,
        borderRadius: BorderRadius.circular(LumRadius.md),
      ),
      child: Row(children: [
        Icon(PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill),
            size: 18, color: lum.textAccent),
        const SizedBox(width: LumSpace.sm),
        Text(formatClock(marker.ms),
            style: LumText.footnote.copyWith(color: lum.textAccent)),
        const SizedBox(width: LumSpace.sm),
        Expanded(
          child: Text(marker.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LumText.subheadline.copyWith(color: lum.textPrimary)),
        ),
      ]),
    );
  }
}

class _LabelCard extends StatelessWidget {
  const _LabelCard({
    required this.ms,
    required this.controller,
    required this.onDone,
  });
  final int ms;
  final TextEditingController controller;
  final void Function({required bool keep}) onDone;

  @override
  Widget build(BuildContext context) {
    final lum = context.lum;
    return Container(
      margin: const EdgeInsets.only(bottom: LumSpace.sm),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: lum.bgGroupedCell,
        borderRadius: BorderRadius.circular(LumRadius.md),
        border: Border.all(color: lum.textAccent, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${NotesStrings.addMarker} ${formatClock(ms)}',
            style: LumText.footnote.copyWith(color: lum.textPrimary)),
        TextField(
          controller: controller,
          autofocus: true,
          maxLength: 60,
          textCapitalization: TextCapitalization.sentences,
          decoration:
              const InputDecoration(hintText: NotesStrings.markerLabelHint),
          onSubmitted: (_) => onDone(keep: true),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton(
            onPressed: () => onDone(keep: false),
            child: const Text(NotesStrings.skip),
          ),
          TextButton(
            onPressed: () => onDone(keep: true),
            child: const Text(NotesStrings.saveLabel),
          ),
        ]),
      ]),
    );
  }
}

/// recording_6: shown once, before the first recording.
class _Consent extends StatelessWidget {
  const _Consent({required this.onAccept, required this.onNotNow});
  final VoidCallback onAccept;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    final lum = context.lum;
    Widget card(IconData icon, String title, String body) => Container(
          margin: const EdgeInsets.only(bottom: LumSpace.md),
          padding: const EdgeInsets.all(LumSpace.lg),
          decoration: BoxDecoration(
            color: lum.bgGroupedCell,
            borderRadius: BorderRadius.circular(LumRadius.md),
            border: Border.all(color: lum.borderSubtle),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: lum.textAccent),
            const SizedBox(width: LumSpace.md),
            Expanded(
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: LumText.subheadlineEmphasized
                        .copyWith(color: lum.textPrimary)),
                const SizedBox(height: 2),
                Text(body,
                    style: LumText.subheadline
                        .copyWith(color: lum.textSecondary)),
              ]),
            ),
          ]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: ListView(children: [
          const SizedBox(height: LumSpace.lg),
          Text(NotesStrings.consentTitle,
              style: LumText.title1.copyWith(color: lum.textPrimary)),
          const SizedBox(height: LumSpace.sm),
          Text(NotesStrings.consentIntro,
              style: LumText.body.copyWith(color: lum.textSecondary)),
          const SizedBox(height: LumSpace.lg),
          card(PhosphorIcons.headphones(), NotesStrings.consentLocalTitle,
              NotesStrings.consentLocalBody),
          card(PhosphorIcons.church(), NotesStrings.consentPolicyTitle,
              NotesStrings.consentPolicyBody),
        ]),
      ),
      LumButton(label: NotesStrings.consentStart, onPressed: onAccept),
      Center(
        child: TextButton(
          onPressed: onNotNow,
          child: const Text(NotesStrings.notNow),
        ),
      ),
      const SizedBox(height: LumSpace.md),
    ]);
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.title,
    required this.body,
    this.action,
    this.onAction,
  });
  final String title;
  final String body;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final lum = context.lum;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(PhosphorIcons.microphoneSlash(), size: 40, color: lum.textAccent),
        const SizedBox(height: LumSpace.lg),
        Text(title,
            textAlign: TextAlign.center,
            style: LumText.title2.copyWith(color: lum.textPrimary)),
        if (body.isNotEmpty) ...[
          const SizedBox(height: LumSpace.sm),
          Text(body,
              textAlign: TextAlign.center,
              style: LumText.body.copyWith(color: lum.textSecondary)),
        ],
        if (action != null) ...[
          const SizedBox(height: LumSpace.xl),
          LumButton(label: action!, onPressed: onAction),
        ],
      ]),
    );
  }
}
