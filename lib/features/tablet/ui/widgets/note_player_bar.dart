import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/features/tablet/domain/recording_note.dart';
import 'package:openbaptisthymnal/features/tablet/providers/recording_providers.dart';
import 'package:openbaptisthymnal/features/tablet/ui/notes_strings.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/note_media_sheet.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Compact (about 68 pt) player pinned above a note that has a recording:
/// back 15 s, play / pause, scrubber with a tick per marker, speed.
class NotePlayerBar extends ConsumerWidget {
  const NotePlayerBar({super.key, required this.markerSeconds});

  /// Seconds of every `t:` link in the note, drawn as ticks on the scrubber.
  final List<int> markerSeconds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lum = context.lum;
    final s = ref.watch(notePlaybackProvider);
    final notifier = ref.read(notePlaybackProvider.notifier);
    final total = s.durationMs;
    final value = total > 0 ? (s.positionMs / total).clamp(0.0, 1.0) : 0.0;
    final mono = LumText.footnote.copyWith(
      fontSize: 12,
      color: lum.textSecondary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Container(
      height: 68,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: lum.bgGroupedCell,
        borderRadius: BorderRadius.circular(LumRadius.md),
        border: Border.all(color: lum.borderSubtle),
      ),
      child: Row(children: [
        IconButton(
          tooltip: NotesStrings.playerBack15,
          onPressed: () => notifier.skip(-15000),
          icon: Icon(PhosphorIcons.clockCounterClockwise(), color: lum.textPrimary),
        ),
        IconButton(
          tooltip: s.playing ? NotesStrings.pause : NotesStrings.play,
          onPressed: notifier.toggle,
          icon: Container(
            width: 40,
            height: 40,
            decoration:
                BoxDecoration(color: lum.bgPrimary, shape: BoxShape.circle),
            child: Icon(
              s.playing
                  ? PhosphorIcons.pause(PhosphorIconsStyle.fill)
                  : PhosphorIcons.play(PhosphorIconsStyle.fill),
              size: 18,
              color: lum.textOnPrimary,
            ),
          ),
        ),
        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              height: 24,
              child: Stack(alignment: Alignment.center, children: [
                Positioned.fill(
                  child: Padding(
                    // The slider's track starts a thumb radius in.
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: CustomPaint(
                      painter: _TickPainter(
                        [
                          if (total > 0)
                            for (final sec in markerSeconds)
                              (sec * 1000 / total).clamp(0.0, 1.0),
                        ],
                        lum.textAccent,
                      ),
                    ),
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    overlayShape: SliderComponentShape.noOverlay,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                    activeTrackColor: lum.textPrimary,
                    inactiveTrackColor: lum.borderSubtle,
                    thumbColor: lum.textPrimary,
                  ),
                  child: Slider(
                    value: value,
                    onChanged: total > 0
                        ? (v) => notifier.seekTo((v * total).round())
                        : null,
                  ),
                ),
              ]),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(formatClock(s.positionMs), style: mono),
              Text(total > 0 ? formatClock(total) : '--:--', style: mono),
            ]),
          ]),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => notifier.setSpeed(
              audioSpeeds[(audioSpeeds.indexOf(s.speed) + 1) % audioSpeeds.length]),
          child: Semantics(
            button: true,
            label: '${NotesStrings.speedLabel} ${speedLabel(s.speed)}',
            excludeSemantics: true,
            child: SizedBox(
              width: 52,
              height: 44,
              child: Center(
                child: Container(
                  width: 48,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: lum.bgSurfaceSunken,
                    borderRadius: BorderRadius.circular(LumRadius.full),
                  ),
                  child: Text(speedLabel(s.speed),
                      style: LumText.footnote
                          .copyWith(color: lum.textPrimary, fontSize: 13)),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _TickPainter extends CustomPainter {
  _TickPainter(this.fractions, this.color);
  final List<double> fractions;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    for (final f in fractions) {
      final x = f * size.width;
      canvas.drawLine(Offset(x, 2), Offset(x, size.height - 2), paint);
    }
  }

  @override
  bool shouldRepaint(_TickPainter old) =>
      old.color != color || !listEquals(old.fractions, fractions);
}
