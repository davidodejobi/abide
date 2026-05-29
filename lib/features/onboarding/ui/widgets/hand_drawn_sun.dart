import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A hand-drawn rising sun (dome + horizon + rays) that draws itself with a
/// pen-stroke effect. Ink color follows the active theme so it stays
/// monochrome in both light and dark mode.
class HandDrawnSun extends StatefulWidget {
  const HandDrawnSun({
    super.key,
    this.size = const Size(220, 150),
    this.duration = const Duration(milliseconds: 1600),
    this.startDelay = Duration.zero,
    this.color,
    this.strokeWidth = 1.5,
  });

  final Size size;
  final Duration duration;
  final Duration startDelay;
  final Color? color;
  final double strokeWidth;

  @override
  State<HandDrawnSun> createState() => _HandDrawnSunState();
}

class _HandDrawnSunState extends State<HandDrawnSun>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _start();
  }

  Future<void> _start() async {
    if (widget.startDelay > Duration.zero) {
      await Future.delayed(widget.startDelay);
    }
    if (mounted) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.color ?? Theme.of(context).colorScheme.onSurface;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: widget.size,
        painter: _SunPainter(
          progress: Curves.easeInOut.transform(_controller.value),
          color: ink,
          strokeWidth: widget.strokeWidth,
        ),
      ),
    );
  }
}

class _SunPainter extends CustomPainter {
  _SunPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final path = _buildPath(size);
    final metrics = path.computeMetrics().toList();
    final totalLength =
        metrics.fold<double>(0, (sum, m) => sum + m.length);
    final drawLength = totalLength * progress;

    final partial = Path();
    double consumed = 0;
    for (final metric in metrics) {
      if (consumed >= drawLength) break;
      final remaining = drawLength - consumed;
      final take = math.min(metric.length, remaining);
      partial.addPath(metric.extractPath(0, take), Offset.zero);
      consumed += metric.length;
    }
    canvas.drawPath(partial, paint);
  }

  /// Builds the full sun as one Path with several subpaths so the pen-stroke
  /// reveal visits them in a natural order: horizon, dome, then rays.
  Path _buildPath(Size size) {
    final path = Path();
    final cx = size.width / 2;
    final horizonY = size.height * 0.72;
    final domeRadius = size.width * 0.22;

    // Horizon line — a gently wavy ground line.
    final hStart = Offset(size.width * 0.06, horizonY + 6);
    path.moveTo(hStart.dx, hStart.dy);
    const hSeg = 10;
    for (var i = 1; i <= hSeg; i++) {
      final t = i / hSeg;
      final x = size.width * 0.06 + (size.width * 0.88) * t;
      final wobble = math.sin(t * math.pi) * 6; // dip toward the middle
      final jitter = math.sin(t * 22) * 0.5;
      path.lineTo(x, horizonY + 6 - wobble + jitter);
    }

    // Dome — a semicircle sitting on the horizon, drawn left→right with jitter.
    const dSeg = 22;
    final domeStart = Offset(cx - domeRadius, horizonY);
    path.moveTo(domeStart.dx, domeStart.dy);
    for (var i = 1; i <= dSeg; i++) {
      final t = i / dSeg;
      final angle = math.pi - t * math.pi; // pi → 0 (left to right, over top)
      final jitter = math.sin(t * 30) * 0.6;
      final x = cx + math.cos(angle) * (domeRadius + jitter);
      final y = horizonY - math.sin(angle) * (domeRadius + jitter);
      path.lineTo(x, y);
    }

    // Rays — short strokes radiating from just outside the dome.
    const rayCount = 7;
    final rayInner = domeRadius + size.width * 0.05;
    final rayOuter = domeRadius + size.width * 0.16;
    for (var i = 0; i < rayCount; i++) {
      final t = i / (rayCount - 1);
      final angle = math.pi - t * math.pi; // spread across the top half
      final dir = Offset(math.cos(angle), -math.sin(angle));
      final start = Offset(cx + dir.dx * rayInner, horizonY + dir.dy * rayInner);
      final end = Offset(cx + dir.dx * rayOuter, horizonY + dir.dy * rayOuter);
      path.moveTo(start.dx, start.dy);
      path.lineTo(end.dx, end.dy);
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant _SunPainter old) =>
      old.progress != progress || old.color != color;
}
