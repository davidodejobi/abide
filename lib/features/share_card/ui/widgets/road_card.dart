import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/features/daily/domain/road_geometry.dart';
import 'package:openbaptisthymnal/features/daily/ui/daily_strings.dart';
import 'package:openbaptisthymnal/features/share_card/ui/share_card_style.dart';
import 'package:openbaptisthymnal/features/tablet/ui/notes_strings.dart';

/// The "Share my road" card: a snapshot of the road at the reader's day, then
/// the day, streak and passage over a solid panel with the Lumway mark. A
/// style with no road asset (Plain) leaves the picture out.
class RoadCard extends StatelessWidget {
  const RoadCard({
    super.key,
    required this.style,
    required this.format,
    required this.day,
    required this.totalDays,
    required this.planTitle,
    this.streak = 0,
    this.passage,
    this.landmarkTitle,
    this.landmarkArt,
  });

  final ShareCardStyle style;
  final ShareCardFormat format;
  final int day;
  final int totalDays;
  final String planTitle;
  final int streak;

  /// Today's passage reference; null hides the line.
  final String? passage;

  /// The landmark nearest the reader and its sprite key (`garden`), if any.
  final String? landmarkTitle;
  final String? landmarkArt;

  @override
  Widget build(BuildContext context) {
    final t = style.tone;
    final showRoad = style.roadAsset != null;
    return AspectRatio(
      aspectRatio: format.aspect,
      child: LayoutBuilder(builder: (context, box) {
        final roadH = box.maxHeight *
            (format == ShareCardFormat.status ? 0.55 : 0.5);
        return ColoredBox(
          color: t.glassFillOpaque,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showRoad)
                ExcludeSemantics(
                  child: SizedBox(
                    height: roadH,
                    child: _RoadPicture(
                      tone: t,
                      day: day,
                      totalDays: totalDays,
                      landmarkArt: landmarkArt,
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(LumSpace.xl),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: box.maxWidth - 2 * LumSpace.xl,
                      child: _Words(card: this),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _Words extends StatelessWidget {
  const _Words({required this.card});

  final RoadCard card;

  @override
  Widget build(BuildContext context) {
    final t = card.style.tone;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DailyStrings.dayOfPlan(card.day, card.planTitle).toUpperCase(),
          style: LumText.roadLabelCaps11.copyWith(color: t.textSecondary),
        ),
        const SizedBox(height: LumSpace.sm),
        if (card.passage != null)
          Text(card.passage!,
              style: LumText.title1.copyWith(color: t.textPrimary)),
        if (card.streak > 0) ...[
          const SizedBox(height: LumSpace.xs),
          Text(DailyStrings.streakCount(card.streak),
              style: LumText.footnoteEmphasized.copyWith(color: t.textAccent)),
        ],
        if (card.landmarkTitle != null) ...[
          const SizedBox(height: LumSpace.xs),
          Text(DailyStrings.nearLandmark(card.landmarkTitle!),
              style: LumText.footnote.copyWith(color: t.textSecondary)),
        ],
        const SizedBox(height: LumSpace.lg),
        Text(NotesStrings.appMark,
            style: LumText.footnoteEmphasized.copyWith(color: t.textPrimary)),
      ],
    );
  }
}

/// A few stops of the road around the reader's day, laid out with the real
/// road geometry, with the nearest landmark standing beside their stop.
class _RoadPicture extends StatelessWidget {
  const _RoadPicture({
    required this.tone,
    required this.day,
    required this.totalDays,
    required this.landmarkArt,
  });

  final LumColors tone;
  final int day;
  final int totalDays;
  final String? landmarkArt;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final layout = RoadLayout(box.biggest, day, totalDays);
      final here = layout.at(day);
      final art = landmarkArt;
      final spriteW = box.maxWidth * 0.3;
      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(child: ColoredBox(color: tone.bgSurfaceSunken)),
          Positioned.fill(
            child: CustomPaint(painter: _RoadPainter(tone, layout)),
          ),
          if (art != null)
            Positioned(
              // Stands on the side away from the road's swing at this stop.
              left: here.dx < box.maxWidth / 2
                  ? here.dx + 20
                  : here.dx - 20 - spriteW,
              top: here.dy - spriteW * 0.8,
              width: spriteW,
              height: spriteW,
              child: Image.asset(
                'assets/images/road/living/lm_$art.webp',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
        ],
      );
    });
  }
}

/// Where each stop lands in a picture of [size] with [day] about a third of
/// the way up. Pure, so tests can check it without a canvas.
class RoadLayout {
  RoadLayout(this.size, this.day, this.totalDays);

  static const _geo = RoadGeometry();
  final Size size;
  final int day;
  final int totalDays;

  double get scale =>
      (size.height * 0.85 / (_geo.spacing * 6)).clamp(0.2, size.width / 330);

  Offset at(int n) {
    final p = _geo.stop(n), here = _geo.stop(day);
    return Offset(
      size.width / 2 + p.x * scale,
      size.height * 0.66 + (p.y - here.y) * scale,
    );
  }

  /// Stops drawn: a few behind and ahead, kept inside the plan.
  Iterable<int> get stops sync* {
    for (var n = day - 3; n <= day + 4; n++) {
      if (n >= 0 && n <= totalDays) yield n;
    }
  }
}

class _RoadPainter extends CustomPainter {
  _RoadPainter(this.tone, this.layout);

  final LumColors tone;
  final RoadLayout layout;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = [for (final n in layout.stops) layout.at(n)];
    final k = layout.scale;
    final path = Path();
    for (final (i, p) in pts.indexed) {
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        final q = pts[i - 1];
        path.quadraticBezierTo(q.dx, (q.dy + p.dy) / 2, p.dx, p.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 18 * k
        ..color = tone.borderSubtle,
    );
    for (final n in layout.stops) {
      final p = layout.at(n);
      final r = 7 * k + 2;
      if (n == layout.day) {
        canvas.drawCircle(p, r * 2.2,
            Paint()..color = tone.textAccent.withValues(alpha: .25));
        canvas.drawCircle(p, r * 1.4, Paint()..color = tone.textAccent);
      } else if (n < layout.day) {
        canvas.drawCircle(p, r, Paint()..color = tone.iconSuccess);
      } else {
        canvas.drawCircle(
            p,
            r,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = tone.textSecondary);
      }
    }
  }

  @override
  bool shouldRepaint(_RoadPainter old) =>
      old.layout.day != layout.day ||
      old.layout.size != layout.size ||
      old.tone != tone;
}
