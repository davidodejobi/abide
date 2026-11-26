import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';
import 'package:openbaptisthymnal/features/bible/ui/open_bible_link.dart';
import 'package:openbaptisthymnal/features/hymn/providers/hymnal_provider.dart';
import 'package:openbaptisthymnal/features/hymn/ui/open_hymn_link.dart';
import 'package:openbaptisthymnal/features/tablet/data/transcribe_engine.dart';
import 'package:openbaptisthymnal/features/tablet/domain/recording_note.dart';
import 'package:openbaptisthymnal/features/tablet/domain/transcript.dart';
import 'package:openbaptisthymnal/features/tablet/providers/recording_providers.dart';
import 'package:openbaptisthymnal/features/tablet/providers/transcript_providers.dart';
import 'package:openbaptisthymnal/features/tablet/ui/notes_strings.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Hymn titles of the English pack, for linking hymns named in a transcript.
final hymnMatcherProvider = FutureProvider<HymnTitleMatcher>((ref) async {
  final pack = await ref.read(hymnalRepositoryProvider).getLanguagePack('en');
  return HymnTitleMatcher([
    for (final e in pack.hymns.entries) HymnTitle(e.key, e.value.title, 'en'),
  ]);
});

/// Starts a transcript of [key]: asks "Replace transcript?" first when a
/// finished one exists, then shows the "Language of the message" sheet
/// (recording_14). Only English can start; the others say so and stay put.
/// On Android, English first asks to download the speech model (no design for
/// that step: same sheet style).
Future<void> showTranscribeSheet(BuildContext context,
    ProviderContainer container, TranscriptKey key) async {
  final notifier = container.read(transcriptProvider(key).notifier);
  // The saved files are read asynchronously on first use.
  for (var i = 0;
      i < 40 &&
          container.read(transcriptProvider(key)).phase ==
              TranscriptPhase.loading;
      i++) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  if (!context.mounted) return;
  final replace =
      container.read(transcriptProvider(key)).transcript?.complete ?? false;
  if (replace) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(NotesStrings.replaceTitle),
        content: const Text(NotesStrings.replaceBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(NotesStrings.cancel)),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(NotesStrings.replace)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
  }
  final wifiPref = container.read(transcriptWifiOnlyProvider);
  final englishMatches =
      container.read(bibleReadingPositionProvider).editionId.startsWith('en');
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: context.lum.bgElevated,
    builder: (_) => _LanguageSheet(
      englishMatches: englishMatches,
      wifiOnlyInitial: wifiPref,
      onStart: (wifiOnly) {
        container.read(transcriptWifiOnlyProvider.notifier).set(wifiOnly);
        container.read(transcriptRequestProvider.notifier).request(key);
        notifier.start('en', wifiOnly: wifiOnly, replace: replace);
      },
    ),
  );
}

class _LanguageSheet extends HookWidget {
  const _LanguageSheet({
    required this.onStart,
    required this.englishMatches,
    required this.wifiOnlyInitial,
  });
  final void Function(bool wifiOnly) onStart;
  final bool englishMatches;
  final bool wifiOnlyInitial;

  @override
  Widget build(BuildContext context) {
    final lum = context.lum;
    final confirming = useState(false);
    final unsupported = useState(false);
    final wifiOnly = useState(wifiOnlyInitial);

    Future<void> pick() async {
      // Never offer a download this phone cannot use.
      if (transcribeNeedsModel && !await transcribeSupported()) {
        unsupported.value = true;
        return;
      }
      if (transcribeNeedsModel && !await whisperModelReady()) {
        confirming.value = true;
        return;
      }
      onStart(wifiOnly.value);
      if (context.mounted) Navigator.of(context).pop();
    }

    Widget row(IconData icon, String title, String body,
        {VoidCallback? onTap}) {
      final on = onTap != null;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: lum.bgGroupedCell,
          borderRadius: BorderRadius.circular(LumRadius.lg),
          child: InkWell(
            borderRadius: BorderRadius.circular(LumRadius.lg),
            onTap: onTap,
            child: Opacity(
              opacity: on ? 1 : 0.55,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  CircleAvatar(
                      radius: 22,
                      backgroundColor: lum.bgSurfaceSunken,
                      child: Icon(icon, size: 22, color: lum.textPrimary)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: LumText.headline
                                  .copyWith(color: lum.textPrimary)),
                          const SizedBox(height: 2),
                          Text(body,
                              style: LumText.footnote
                                  .copyWith(color: lum.textSecondary)),
                        ]),
                  ),
                  if (on)
                    Icon(PhosphorIcons.caretRight(),
                        size: 18, color: lum.textSecondary),
                ]),
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: unsupported.value
              ? [
                  Text(NotesStrings.transcriptUnavailablePhone,
                      style: LumText.title2.copyWith(color: lum.textPrimary)),
                  const SizedBox(height: 8),
                  Text(NotesStrings.transcriptUnavailablePhoneBody,
                      style: LumText.subheadline
                          .copyWith(color: lum.textSecondary)),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(NotesStrings.close),
                  ),
                ]
              : confirming.value
                  ? [
                      Text(NotesStrings.modelDownloadTitle,
                          style:
                              LumText.title2.copyWith(color: lum.textPrimary)),
                      const SizedBox(height: 8),
                      Text(
                          NotesStrings.modelDownloadBody(
                              (whisperModelBytes / 1000000).round()),
                          style: LumText.subheadline
                              .copyWith(color: lum.textSecondary)),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(NotesStrings.wifiOnly),
                        value: wifiOnly.value,
                        onChanged: (v) => wifiOnly.value = v,
                      ),
                      FilledButton(
                        onPressed: () {
                          onStart(wifiOnly.value);
                          Navigator.of(context).pop();
                        },
                        child: const Text(NotesStrings.downloadAndStart),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(NotesStrings.notNow),
                      ),
                    ]
                  : [
                      Text(NotesStrings.languageTitle,
                          style:
                              LumText.title2.copyWith(color: lum.textPrimary)),
                      const SizedBox(height: 16),
                      row(
                          PhosphorIcons.headphones(),
                          transcriptLanguages['en']!,
                          englishMatches
                              ? NotesStrings.englishRowBody
                              : NotesStrings.englishRowBodyFree,
                          onTap: pick),
                      row(PhosphorIcons.textAa(), transcriptLanguages['yo']!,
                          NotesStrings.yorubaRowBody),
                      row(
                          PhosphorIcons.sparkle(),
                          NotesStrings.otherLanguagesRow,
                          NotesStrings.unavailableRowBody),
                      Text(NotesStrings.mixedLanguages,
                          style: LumText.footnote
                              .copyWith(color: lum.textSecondary)),
                    ],
        ),
      ),
    );
  }
}

/// The Transcript tab: progress, the failure and empty states, or the
/// transcript itself.
class TranscriptView extends HookConsumerWidget {
  const TranscriptView({
    super.key,
    required this.audioKey,
    required this.audioPath,
    required this.speed,
    required this.recordingName,
    required this.manifest,
    required this.followAlong,
    required this.onCopyToNote,
    required this.onShowNote,
  });

  final TranscriptKey audioKey;
  final String audioPath;
  final int speed;
  final String recordingName;
  final BibleManifest? manifest;
  final bool followAlong;
  final void Function(List<TranscriptSegment>) onCopyToNote;
  final VoidCallback onShowNote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(transcriptProvider(audioKey));
    final notifier = ref.read(transcriptProvider(audioKey).notifier);
    final t = s.transcript;
    final lum = context.lum;

    final container = ProviderScope.containerOf(context);
    Future<void> openSheet() =>
        showTranscribeSheet(context, container, audioKey);
    final hymns = ref.watch(hymnMatcherProvider).valueOrNull;
    final hasSaved = t != null && t.segments.isNotEmpty;
    // After a failure the saved part (or the finished transcript a replacement
    // run did not touch) can still be read.
    final keepLabel =
        hasSaved ? NotesStrings.readSaved : NotesStrings.keepRecordingOnly;
    final keep = hasSaved ? notifier.dismissFailure : onShowNote;

    switch (s.phase) {
      case TranscriptPhase.loading:
        return const Center(child: CircularProgressIndicator());
      case TranscriptPhase.queued:
        return _Progress(
          title: s.stopping
              ? NotesStrings.stopping
              : NotesStrings.waitingForAnother,
          subtitle: NotesStrings.waitingForAnotherBody,
          progress: 0,
          showSteps: false,
          onCancel: s.stopping ? null : notifier.cancel,
        );
      case TranscriptPhase.downloading:
      case TranscriptPhase.running:
        final downloading = s.phase == TranscriptPhase.downloading;
        return _Progress(
          title: s.stopping
              ? NotesStrings.stopping
              : downloading
                  ? NotesStrings.downloadingModelTitle
                  : NotesStrings.transcribingOnPhone,
          subtitle: '$recordingName · ${formatClock(audioKey.durationMs)}',
          progress: s.progress,
          showSteps: !downloading,
          onCancel: s.stopping ? null : notifier.cancel,
        );
      case TranscriptPhase.idle:
        break;
    }

    switch (s.failure) {
      case TranscribeFailure.denied:
        return _Status(
          icon: PhosphorIcons.microphone(),
          title: NotesStrings.speechDeniedTitle,
          subtitle: NotesStrings.speechDeniedBody,
          cards: [
            (
              PhosphorIcons.headphones(),
              NotesStrings.step1OpenSettings,
              NotesStrings.speechSettingsHint
            ),
            (
              PhosphorIcons.sparkle(),
              NotesStrings.notesAreSafe,
              NotesStrings.notesAreSafeBody
            ),
          ],
          primary: NotesStrings.openSettings,
          onPrimary: () => launchUrl(Uri.parse('app-settings:')),
          secondary: NotesStrings.notNow,
          onSecondary: onShowNote,
        );
      case TranscribeFailure.unsupported:
        return _Status(
          icon: PhosphorIcons.info(),
          title: NotesStrings.transcriptUnavailable,
          subtitle: NotesStrings.notesAreSafeBody,
          primary: NotesStrings.tryAgain,
          onPrimary: openSheet,
          secondary: NotesStrings.keepRecordingOnly,
          onSecondary: onShowNote,
        );
      case TranscribeFailure.model:
        return _Status(
          icon: PhosphorIcons.info(),
          title: NotesStrings.modelFailedTitle,
          subtitle: NotesStrings.didNotFinishBody,
          cards: [
            (
              PhosphorIcons.headphones(),
              NotesStrings.whatYouCanDo,
              NotesStrings.modelFailedBody
            ),
          ],
          primary: NotesStrings.tryAgain,
          onPrimary: notifier.retry,
          secondary: keepLabel,
          onSecondary: keep,
        );
      case TranscribeFailure.failed:
        return _Status(
          icon: PhosphorIcons.info(),
          title: NotesStrings.didNotFinish,
          subtitle: NotesStrings.didNotFinishBody,
          cards: [
            (
              PhosphorIcons.headphones(),
              NotesStrings.whatHappened,
              t != null && t.doneMs > 0
                  ? NotesStrings.stoppedAt(
                      formatClock(t.doneMs),
                      formatClock(t.durationMs > 0
                          ? t.durationMs
                          : audioKey.durationMs))
                  : NotesStrings.transcribeFailedBody
            ),
            (
              PhosphorIcons.sparkle(),
              NotesStrings.whatYouCanDo,
              NotesStrings.tryAgainHint
            ),
          ],
          primary: NotesStrings.tryAgain,
          onPrimary: notifier.retry,
          secondary: keepLabel,
          onSecondary: keep,
        );
      case TranscribeFailure.waitingForWifi:
        return _Status(
          icon: PhosphorIcons.info(),
          title: NotesStrings.waitingForWifiTitle,
          subtitle: NotesStrings.waitingForWifiBody,
          primary: NotesStrings.useMobileData,
          onPrimary: () => notifier.start(t?.language ?? 'en',
              wifiOnly: false, replace: t?.complete ?? false),
          secondary: NotesStrings.notNow,
          onSecondary: onShowNote,
        );
      case TranscribeFailure.deviceUnsupported:
        return _Status(
          icon: PhosphorIcons.info(),
          title: NotesStrings.transcriptUnavailablePhone,
          subtitle: NotesStrings.transcriptUnavailablePhoneBody,
          secondary: NotesStrings.keepRecordingOnly,
          onSecondary: onShowNote,
        );
      case TranscribeFailure.cancelled:
      case null:
        break;
    }

    if (t == null || (t.segments.isEmpty && !t.complete)) {
      return _Status(
        icon: PhosphorIcons.article(),
        title: NotesStrings.transcriptEmptyTitle,
        subtitle: NotesStrings.transcribeBody,
        primary: NotesStrings.transcribe,
        onPrimary: openSheet,
      );
    }
    if (t.segments.isEmpty) {
      return _Status(
        icon: PhosphorIcons.info(),
        title: NotesStrings.noSpeechFound,
        subtitle: NotesStrings.notesAreSafeBody,
        secondary: NotesStrings.keepRecordingOnly,
        onSecondary: onShowNote,
      );
    }

    return _Rows(
      segments: t.segments,
      audioPath: audioPath,
      durationMs: audioKey.durationMs,
      speed: speed,
      manifest: manifest,
      hymns: hymns,
      followAlong: followAlong,
      partial: !t.complete,
      onResume: () => notifier.start(t.language),
      onCopyToNote: () => onCopyToNote(t.segments),
      background: lum.bgPage,
    );
  }
}

// ---- states -----------------------------------------------------------

class _Progress extends StatelessWidget {
  const _Progress({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.showSteps,
    required this.onCancel,
  });
  final String title;
  final String subtitle;
  final double progress;
  final bool showSteps;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final lum = context.lum;
    Widget step(IconData icon, String label,
            {bool done = false, bool on = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Icon(icon,
                size: 22, color: done ? lum.iconSuccess : lum.textSecondary),
            const SizedBox(width: 12),
            Text(label,
                style: (on
                        ? LumText.subheadlineEmphasized
                        : LumText.subheadline)
                    .copyWith(
                        color:
                            on || done ? lum.textPrimary : lum.textSecondary)),
          ]),
        );
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      children: [
        Center(
          child: CircleAvatar(
              radius: 28,
              backgroundColor: lum.bgAccentContainer,
              child: Icon(PhosphorIcons.flame(PhosphorIconsStyle.fill),
                  color: lum.textOnAccentContainer)),
        ),
        const SizedBox(height: 16),
        Text(title,
            textAlign: TextAlign.center,
            style: LumText.title2.copyWith(color: lum.textPrimary)),
        const SizedBox(height: 8),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: LumText.subheadline.copyWith(color: lum.textSecondary)),
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(LumRadius.full),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            color: lum.textPrimary,
            backgroundColor: lum.borderSubtle,
          ),
        ),
        const SizedBox(height: 6),
        Text('${(progress * 100).round()}%',
            style: LumText.footnoteEmphasized.copyWith(color: lum.textPrimary)),
        if (showSteps) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: lum.bgGroupedCell,
              borderRadius: BorderRadius.circular(LumRadius.lg),
            ),
            child: Column(children: [
              step(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                  NotesStrings.stepAudioPrepared,
                  done: true),
              step(PhosphorIcons.clockCounterClockwise(),
                  NotesStrings.stepWriting,
                  on: true),
              step(PhosphorIcons.article(), NotesStrings.stepReady),
            ]),
          ),
        ],
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: onCancel,
            child: Text(NotesStrings.cancelTranscription,
                style: LumText.subheadlineEmphasized
                    .copyWith(color: lum.textSecondary)),
          ),
        ),
      ],
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.cards = const [],
    this.primary,
    this.onPrimary,
    this.secondary,
    this.onSecondary,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final List<(IconData, String, String)> cards;
  final String? primary;
  final VoidCallback? onPrimary;
  final String? secondary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final lum = context.lum;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: CircleAvatar(
              radius: 28,
              backgroundColor: lum.bgSuccessContainer,
              child: Icon(icon, color: lum.iconSuccess)),
        ),
        const SizedBox(height: 16),
        Text(title, style: LumText.title1.copyWith(color: lum.textPrimary)),
        const SizedBox(height: 8),
        Text(subtitle, style: LumText.body.copyWith(color: lum.textSecondary)),
        const SizedBox(height: 16),
        for (final c in cards)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: lum.bgGroupedCell,
              borderRadius: BorderRadius.circular(LumRadius.lg),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(
                  radius: 22,
                  backgroundColor: lum.bgSuccessContainer,
                  child: Icon(c.$1, size: 22, color: lum.iconSuccess)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.$2,
                          style: LumText.headline
                              .copyWith(color: lum.textPrimary)),
                      const SizedBox(height: 2),
                      Text(c.$3,
                          style: LumText.footnote
                              .copyWith(color: lum.textSecondary)),
                    ]),
              ),
            ]),
          ),
        if (primary != null)
          SizedBox(
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: lum.bgPrimary,
                foregroundColor: lum.textOnPrimary,
                shape: const StadiumBorder(),
              ),
              onPressed: onPrimary,
              child: Text(primary!),
            ),
          ),
        if (secondary != null)
          Center(
            child: TextButton(
              onPressed: onSecondary,
              child: Text(secondary!,
                  style: LumText.subheadlineEmphasized
                      .copyWith(color: lum.textPrimary)),
            ),
          ),
      ],
    );
  }
}

// ---- the transcript ------------------------------------------------------

class _Rows extends HookConsumerWidget {
  const _Rows({
    required this.segments,
    required this.audioPath,
    required this.durationMs,
    required this.speed,
    required this.manifest,
    required this.hymns,
    required this.followAlong,
    required this.partial,
    required this.onResume,
    required this.onCopyToNote,
    required this.background,
  });

  final List<TranscriptSegment> segments;
  final String audioPath;
  final int durationMs;
  final int speed;
  final BibleManifest? manifest;
  final HymnTitleMatcher? hymns;
  final bool followAlong;
  final bool partial;
  final VoidCallback onResume;
  final VoidCallback onCopyToNote;
  final Color background;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lum = context.lum;
    final query = useState('');
    final rawQuery = useState('');
    final current = useState(0); // which match, 0-based
    final lastUserScroll = useRef(DateTime.fromMillisecondsSinceEpoch(0));
    final keys = useMemoized(() => <int, GlobalKey>{}, [segments.length]);
    final groups = useMemoized(() => groupSegments(segments), [segments]);
    final allPieces = transcriptPieces(segments, manifest, hymns);
    final playback = ref.read(notePlaybackProvider.notifier);

    // The segment playing now, only while this note's clip is playing.
    final active = ref.watch(notePlaybackProvider.select((s) =>
        s.path == audioPath && s.playing
            ? activeSegmentIndex(segments, s.positionMs)
            : -1));

    // Every search hit as (segment index); one entry per occurrence.
    final q = query.value.trim().toLowerCase();
    final hits = useMemoized(
        () => [
              if (q.isNotEmpty)
                for (var i = 0; i < segments.length; i++)
                  for (var at = segments[i].text.toLowerCase().indexOf(q);
                      at != -1;
                      at = segments[i]
                          .text
                          .toLowerCase()
                          .indexOf(q, at + q.length))
                    i,
            ],
        [segments, q]);

    // Search runs 150 ms after the last keystroke.
    useEffect(() {
      final timer = Timer(const Duration(milliseconds: 150), () {
        query.value = rawQuery.value;
        current.value = 0;
      });
      return timer.cancel;
    }, [rawQuery.value]);

    void reveal(int index) {
      final ctx = keys[index]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            alignment: 0.3, duration: const Duration(milliseconds: 250));
      }
    }

    useEffect(() {
      if (!followAlong || active < 0) return null;
      if (DateTime.now().difference(lastUserScroll.value) <
          const Duration(seconds: 5)) {
        return null;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => reveal(active));
      return null;
    }, [active, followAlong]);

    void jump(int delta) {
      if (hits.isEmpty) return;
      current.value = (current.value + delta) % hits.length;
      if (current.value < 0) current.value += hits.length;
      lastUserScroll.value = DateTime.now();
      reveal(hits[current.value]);
    }

    Future<void> seek(int ms) async {
      playback.load(audioPath, durationMs: durationMs, speed: speed);
      await playback.seekAndPlay(ms ~/ 1000);
    }

    final currentSegment =
        hits.isEmpty ? -1 : hits[current.value % hits.length];

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Container(
          height: 48,
          padding: const EdgeInsets.only(left: 14, right: 4),
          decoration: BoxDecoration(
            color: lum.bgGroupedCell,
            borderRadius: BorderRadius.circular(LumRadius.lg),
            border: Border.all(
                color: q.isEmpty ? lum.borderSubtle : lum.textAccent,
                width: q.isEmpty ? 1 : 2),
          ),
          child: Row(children: [
            Icon(PhosphorIcons.magnifyingGlass(),
                size: 20, color: lum.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: (v) => rawQuery.value = v,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: NotesStrings.searchTranscript,
                ),
              ),
            ),
            if (q.isNotEmpty) ...[
              Text(
                  hits.isEmpty
                      ? '0'
                      : '${current.value % hits.length + 1} of ${hits.length}',
                  style: LumText.footnote.copyWith(color: lum.textSecondary)),
              IconButton(
                  tooltip: 'Previous match',
                  onPressed: () => jump(-1),
                  icon: Icon(PhosphorIcons.caretUp(), size: 18)),
              IconButton(
                  tooltip: 'Next match',
                  onPressed: () => jump(1),
                  icon: Icon(PhosphorIcons.caretDown(), size: 18)),
            ],
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        child: Row(children: [
          Icon(PhosphorIcons.info(), size: 14, color: lum.textSecondary),
          const SizedBox(width: 6),
          Text(NotesStrings.transcriptPrivacy,
              style: LumText.caption.copyWith(color: lum.textSecondary)),
        ]),
      ),
      Expanded(
        child: NotificationListener<ScrollStartNotification>(
          onNotification: (n) {
            if (n.dragDetails != null) lastUserScroll.value = DateTime.now();
            return false;
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final g in groups)
                _Group(
                  indexes: g,
                  segments: segments,
                  active: active,
                  currentHit: currentSegment,
                  query: q,
                  pieces: allPieces,
                  keyFor: (i) => keys.putIfAbsent(i, GlobalKey.new),
                  onSeek: seek,
                  onOpenRef: (key) =>
                      openBibleLink(context, ref, targetKey: key),
                  onOpenHymn: (h) => openHymnLink(context, ref,
                      targetKey: h.id, editionPin: h.pack),
                ),
              Row(children: [
                TextButton(
                    onPressed: onCopyToNote,
                    child: const Text(NotesStrings.copyToNote)),
                if (partial)
                  TextButton(
                      onPressed: onResume,
                      child: const Text(NotesStrings.transcriptResume)),
              ]),
            ]),
          ),
        ),
      ),
    ]);
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.indexes,
    required this.segments,
    required this.active,
    required this.currentHit,
    required this.query,
    required this.pieces,
    required this.keyFor,
    required this.onSeek,
    required this.onOpenRef,
    required this.onOpenHymn,
  });
  final List<int> indexes;
  final List<TranscriptSegment> segments;
  final int active;
  final int currentHit;
  final String query;
  final List<List<TranscriptPiece>> pieces;
  final GlobalKey Function(int) keyFor;
  final Future<void> Function(int ms) onSeek;
  final void Function(String targetKey) onOpenRef;
  final void Function(HymnTitle hymn) onOpenHymn;

  @override
  Widget build(BuildContext context) {
    final lum = context.lum;
    final live = indexes.contains(active);
    final start = segments[indexes.first].startMs;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: () => onSeek(start),
          child: Container(
            height: 32,
            margin: const EdgeInsets.only(top: 4, right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: live ? lum.bgInverse : lum.bgAccentContainer,
              borderRadius: BorderRadius.circular(LumRadius.full),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(PhosphorIcons.play(PhosphorIconsStyle.fill),
                  size: 12,
                  color: live ? lum.textInverse : lum.textOnAccentContainer),
              const SizedBox(width: 4),
              Text(formatClock(start),
                  style: LumText.footnoteEmphasized.copyWith(
                      color: live ? lum.textInverse : lum.textOnAccentContainer,
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ]),
          ),
        ),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final i in indexes)
              GestureDetector(
                key: keyFor(i),
                behavior: HitTestBehavior.opaque,
                onTap: () => onSeek(segments[i].startMs),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: i == active
                      ? BoxDecoration(
                          color: lum.bgAccentContainer,
                          borderRadius: BorderRadius.circular(LumRadius.md),
                          border: Border.all(color: lum.textAccent),
                        )
                      : null,
                  child: SegmentText(
                    pieces: pieces[i],
                    query: query,
                    strongHit: i == currentHit,
                    onOpenRef: onOpenRef,
                    onOpenHymn: onOpenHymn,
                  ),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

/// One paragraph: Bible references are tappable, search hits are marked.
class SegmentText extends HookWidget {
  const SegmentText({
    super.key,
    required this.pieces,
    required this.query,
    required this.strongHit,
    required this.onOpenRef,
    required this.onOpenHymn,
  });
  final List<TranscriptPiece> pieces;
  final String query;
  final bool strongHit;
  final void Function(String targetKey) onOpenRef;
  final void Function(HymnTitle hymn) onOpenHymn;

  @override
  Widget build(BuildContext context) {
    final lum = context.lum;
    final recognizers = useMemoized(
        () => [
              for (final p in pieces)
                p.targetKey != null
                    ? (TapGestureRecognizer()
                      ..onTap = () => onOpenRef(p.targetKey!))
                    : p.hymn != null
                        ? (TapGestureRecognizer()
                          ..onTap = () => onOpenHymn(p.hymn!))
                        : null,
            ],
        [pieces]);
    useEffect(
        () => () {
              for (final r in recognizers) {
                r?.dispose();
              }
            },
        [recognizers]);

    final base = LumText.readingLyricsCompact.copyWith(color: lum.textPrimary);
    final mark = TextStyle(
        backgroundColor: strongHit
            ? lum.highlightSun
            : lum.highlightSun.withValues(alpha: 0.4));

    List<InlineSpan> hits(String s, TextStyle style, GestureRecognizer? r) {
      if (query.isEmpty) {
        return [TextSpan(text: s, style: style, recognizer: r)];
      }
      final out = <InlineSpan>[];
      final low = s.toLowerCase();
      var cursor = 0;
      for (var at = low.indexOf(query);
          at != -1;
          at = low.indexOf(query, cursor)) {
        if (at > cursor) {
          out.add(TextSpan(
              text: s.substring(cursor, at), style: style, recognizer: r));
        }
        out.add(TextSpan(
            text: s.substring(at, at + query.length),
            style: style.merge(mark),
            recognizer: r));
        cursor = at + query.length;
      }
      if (cursor < s.length) {
        out.add(
            TextSpan(text: s.substring(cursor), style: style, recognizer: r));
      }
      return out;
    }

    return Text.rich(TextSpan(children: [
      for (var i = 0; i < pieces.length; i++)
        ...hits(
          pieces[i].text,
          pieces[i].targetKey == null && pieces[i].hymn == null
              ? base
              : base.copyWith(
                  color: lum.textAccent,
                  decoration: TextDecoration.underline,
                  decorationColor: lum.textAccent),
          recognizers[i],
        ),
    ]));
  }
}
