import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';

import '../../domain/landmark_spin.dart';
import 'road_art.dart';

/// Where a landmark sheet's picture came from on the road, and when it has
/// finished flying home again. The caller waits on [settled] so the road can
/// show the sprite again only once it has landed.
class ShowcaseFlight {
  ShowcaseFlight(this.from);

  /// The sprite's rect on the road, in global coordinates.
  final Rect? from;
  bool backStarted = false;
  final _done = Completer<void>();

  Future<void> get settled => _done.future
      .timeout(const Duration(seconds: 2), onTimeout: () {});

  void finish() {
    if (!_done.isCompleted) _done.complete();
  }
}

// ------------------------------------------------------------------ physics
class _Whoosh extends Simulation {
  _Whoosh(this.from, this.turns, this.seconds);
  final double from, turns, seconds;

  @override
  double x(double t) =>
      from + turns * Curves.easeOutCubic.transform((t / seconds).clamp(0, 1));

  @override
  double dx(double t) => (x(t + .001) - x(t)) / .001;

  @override
  bool isDone(double t) => t >= seconds;
}

class _Idle extends Simulation {
  _Idle(this.from, this.turnsPerSecond);
  final double from, turnsPerSecond;

  @override
  double x(double t) => from + turnsPerSecond * t;

  @override
  double dx(double t) => turnsPerSecond;

  @override
  bool isDone(double t) => false;
}

// ------------------------------------------------------------------ widget
/// The showcase header of a landmark sheet: the sprite lifts off the road and
/// flies here, lands on a lit podium, spins, and the title reveals. Drag to
/// spin it yourself.
class LandmarkShowcase extends StatefulWidget {
  const LandmarkShowcase({
    super.key,
    required this.art,
    required this.sprite,
    required this.eyebrow,
    required this.title,
    this.flight,
  });

  final String art;
  final ui.Image sprite;
  final String eyebrow, title;
  final ShowcaseFlight? flight;

  @override
  State<LandmarkShowcase> createState() => _LandmarkShowcaseState();
}

class _LandmarkShowcaseState extends State<LandmarkShowcase>
    with TickerProviderStateMixin {
  static const _stageHeight = 290.0;
  static const _heroSize = 210.0;

  final _slot = GlobalKey();
  late final ui.Image _mine = widget.sprite.clone();
  late final _spin = AnimationController.unbounded(vsync: this);
  late final _clock =
      AnimationController(vsync: this, duration: const Duration(seconds: 6));
  late final _reveal =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final _burst =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  /// The decoded turntable; null until ready (the static sprite stands in).
  ui.Image? _sheet;
  List<Color> _palette = const [];
  bool _landed = false;
  bool _init = false, _reduce = false, _flying = false, _started = false;
  bool _dragging = false;
  Rect _lastSlot = Rect.zero;
  OverlayEntry? _entry;
  Animation<double>? _route;

  @override
  void initState() {
    super.initState();
    _spin.addStatusListener((s) {
      // A whoosh or a fling has run out: settle into the slow idle turn.
      if (s == AnimationStatus.completed && mounted && !_dragging && !_reduce) {
        _spin.animateWith(_Idle(_spin.value, .06));
      }
    });
    scheduleMicrotask(() {
      if (mounted) {
        _loadPalette();
        _loadSheet();
      }
    });
  }

  Future<void> _loadSheet() async {
    try {
      final img = await RoadArt.loadSpin(widget.art);
      if (!mounted) {
        img.dispose();
        return;
      }
      final old = _sheet;
      setState(() => _sheet = img);
      old?.dispose();
      _maybeSpin();
    } catch (_) {}
  }

  Future<void> _loadPalette() async {
    try {
      final bytes = await _mine.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (bytes == null || !mounted) return;
      final p = spinPalette(bytes.buffer.asUint8List());
      if (p.isNotEmpty && mounted) {
        setState(() => _palette = [for (final v in p) Color(v)]);
      }
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    _reduce = MediaQuery.disableAnimationsOf(context);
    _flying = widget.flight?.from != null && !_reduce;
    _route = ModalRoute.of(context)?.animation?..addStatusListener(_routeStatus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_flying) {
        _startFlight();
      } else {
        _land();
      }
    });
  }

  @override
  void dispose() {
    _route?.removeStatusListener(_routeStatus);
    _entry?.remove();
    _entry = null;
    if (widget.flight?.backStarted != true) widget.flight?.finish();
    _spin.dispose();
    _clock.dispose();
    _reveal.dispose();
    _burst.dispose();
    _mine.dispose();
    _sheet?.dispose();
    _sheet = null;
    super.dispose();
  }

  Rect _slotRect() {
    final o = _slot.currentContext?.findRenderObject();
    if (o is RenderBox && o.attached && o.hasSize) {
      _lastSlot = o.localToGlobal(Offset.zero) & o.size;
    }
    return _lastSlot;
  }

  Color get _glow {
    return _palette.isEmpty ? context.lum.sceneGlow : _palette.first;
  }

  void _startFlight() {
    final from = widget.flight!.from!;
    _lastSlot = from;
    // Cloned and resolved once, here: a builder runs again on any overlay
    // rebuild, and the flier owns (disposes) this one handle.
    final image = _mine.clone();
    final glow = _glow;
    final entry = OverlayEntry(
      builder: (_) => _Flier(
        image: image,
        from: from,
        to: _slotRect,
        glow: glow,
        onDone: () {
          _entry?.remove();
          _entry = null;
          if (mounted) _land();
        },
      ),
    );
    _entry = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  void _routeStatus(AnimationStatus s) {
    final f = widget.flight;
    if (s != AnimationStatus.reverse || f == null || f.from == null) return;
    if (f.backStarted || _reduce) return;
    f.backStarted = true;
    _entry?.remove();
    _entry = null;
    final start = _slotRect();
    final image = _mine.clone();
    final glow = _glow;
    setState(() => _flying = true); // the flier is the only copy on screen
    late final OverlayEntry back;
    back = OverlayEntry(
      builder: (_) => _Flier(
        image: image,
        from: start,
        to: () => f.from!,
        glow: glow,
        back: true,
        onDone: () {
          back.remove();
          f.finish();
        },
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(back);
  }

  void _land() {
    setState(() {
      _flying = false;
      _landed = true;
    });
    HapticFeedback.lightImpact();
    _reveal.duration = Duration(milliseconds: _reduce ? 250 : 900);
    _reveal.forward();
    if (!_reduce) {
      _burst.forward();
      _clock.repeat();
    }
    _maybeSpin();
  }

  /// The whoosh plays once the picture has landed and the turntable is ready.
  void _maybeSpin() {
    if (_started || !_landed || _sheet == null) return;
    _started = true;
    if (!_reduce) _spin.animateWith(_Whoosh(_spin.value, 2, 1.2));
  }

  void _dragStart(DragStartDetails d) {
    _dragging = true;
    _spin.stop();
  }

  void _dragUpdate(DragUpdateDetails d) => _spin.value += dragTurns(d.delta.dx);

  void _dragEnd(DragEndDetails d) {
    _dragging = false;
    if (_reduce) return;
    final v = flingTurnsPerSecond(d.velocity.pixelsPerSecond.dx);
    _spin.animateWith(v.abs() < .05
        ? _Idle(_spin.value, .06)
        : FrictionSimulation(.12, _spin.value, v,
            tolerance: const Tolerance(distance: .001, velocity: .02)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    final sheet = _sheet;
    final colors = _palette.isEmpty ? [c.sceneGlow] : _palette;
    final live = _landed && !_reduce;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _stageHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _StagePainter(
                      repaint: Listenable.merge([_reveal, _burst]),
                      reveal: _reveal,
                      burst: _burst,
                      colors: colors,
                      surface: c.bgSurface,
                      edge: c.borderSubtle,
                      ink: c.textPrimary,
                      reduce: _reduce,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 36,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    excludeFromSemantics: true,
                    onHorizontalDragStart: sheet == null ? null : _dragStart,
                    onHorizontalDragUpdate: sheet == null ? null : _dragUpdate,
                    onHorizontalDragEnd: sheet == null ? null : _dragEnd,
                    child: SizedBox(
                      key: _slot,
                      width: _heroSize,
                      height: _heroSize,
                      child: ExcludeSemantics(
                        child: Opacity(
                          opacity: _flying ? 0 : 1,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: sheet == null
                                ? RawImage(
                                    key: const ValueKey('showcase-static'),
                                    image: _mine,
                                    fit: BoxFit.contain)
                                : RepaintBoundary(
                                    key: const ValueKey('showcase-spin'),
                                    child: CustomPaint(
                                      painter: _SpinPainter(
                                        sheet: sheet,
                                        turns: _spin,
                                        clock: _clock,
                                        bob: live,
                                      ),
                                      size: const Size.square(_heroSize),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (live)
                Positioned.fill(
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _SparklePainter(
                            clock: _clock, reveal: _reveal, colors: colors),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: LumSpace.md),
        _stagger(0, .5, Text(widget.eyebrow.toUpperCase(),
            style: LumText.roadLabelCaps11.copyWith(color: c.textSecondary))),
        const SizedBox(height: LumSpace.xs),
        _stagger(
            .15,
            .75,
            Semantics(
              header: true,
              child: Text(widget.title,
                  style: LumText.title1.copyWith(color: c.textPrimary)),
            ),
            lift: 18),
        const SizedBox(height: LumSpace.sm),
        _stagger(
            .4,
            1,
            Align(
              alignment: Alignment.centerLeft,
              child: _Bar(grow: _reveal, color: colors.first, reduce: _reduce),
            )),
      ],
    );
  }

  /// Fades and slides a block in over [a]..[b] of the reveal; under reduced
  /// motion it only fades, all together.
  Widget _stagger(double a, double b, Widget child, {double lift = 10}) {
    final curve = Interval(a, b, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: _reveal,
      child: child,
      builder: (_, child) {
        final t = _reduce ? _reveal.value : curve.transform(_reveal.value);
        return Opacity(
          opacity: t,
          alwaysIncludeSemantics: true,
          child: Transform.translate(
              offset: Offset(0, _reduce ? 0 : (1 - t) * lift), child: child),
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.grow, required this.color, required this.reduce});

  final Animation<double> grow;
  final Color color;
  final bool reduce;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: grow,
        builder: (_, __) => Container(
          width: 44 * (reduce ? 1 : grow.value),
          height: 4,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
      );
}

// ------------------------------------------------------------------ flight
/// The sprite in flight, on the root overlay: it lifts off (bigger, glowing),
/// then arcs to [to] with a small overshoot. Going back it simply glides home.
class _Flier extends StatefulWidget {
  const _Flier({
    required this.image,
    required this.from,
    required this.to,
    required this.glow,
    required this.onDone,
    this.back = false,
  });

  final ui.Image image;
  final Rect from;
  final Rect Function() to;
  final Color glow;
  final bool back;
  final VoidCallback onDone;

  @override
  State<_Flier> createState() => _FlierState();
}

class _FlierState extends State<_Flier> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.back ? 420 : 780))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    })
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    widget.image.dispose();
    super.dispose();
  }

  Rect _rect(double t) {
    final a = widget.from, b = widget.to();
    if (widget.back) {
      final e = Curves.easeInCubic.transform(t);
      return Rect.lerp(a, b, e)!;
    }
    // 0..0.22 lift in place; then fly, overshooting size slightly (bounce).
    const lift = .22;
    final big = Rect.fromCenter(
        center: a.center.translate(0, -14),
        width: a.width * 1.14,
        height: a.height * 1.14);
    if (t < lift) {
      return Rect.lerp(a, big, Curves.easeOut.transform(t / lift))!;
    }
    final u = (t - lift) / (1 - lift);
    final pos = Curves.easeInOutCubic.transform(u);
    final size = Curves.easeOutBack.transform(u);
    final center = Offset.lerp(big.center, b.center, pos)!
        .translate(0, -math.sin(math.pi * pos) * 36);
    final w = ui.lerpDouble(big.width, b.width, size)!;
    final h = ui.lerpDouble(big.height, b.height, size)!;
    return Rect.fromCenter(center: center, width: w, height: h);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final r = _rect(_c.value);
          final glowA = widget.back
              ? (1 - _c.value) * .5
              : math.sin(math.pi * _c.value.clamp(0, 1)) * .7;
          return Stack(
            children: [
              Positioned.fromRect(
                rect: r.inflate(r.shortestSide * .35),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(colors: [
                      widget.glow.withValues(alpha: glowA),
                      widget.glow.withValues(alpha: 0),
                    ]),
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: r,
                child: RawImage(image: widget.image, fit: BoxFit.contain),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ------------------------------------------------------------------ painters
class _SpinPainter extends CustomPainter {
  _SpinPainter({
    required this.sheet,
    required this.turns,
    required this.clock,
    required this.bob,
  }) : super(repaint: Listenable.merge([turns, clock]));

  final ui.Image sheet;
  final Animation<double> turns, clock;
  final bool bob;
  final _paint = Paint()..filterQuality = FilterQuality.medium;

  @override
  void paint(Canvas canvas, Size size) {
    final f = spinFrameFor(turns.value);
    final cell = sheet.width / spinColumns;
    final src = Rect.fromLTWH(
        (f % spinColumns) * cell, (f ~/ spinColumns) * cell, cell, cell);
    final dy = bob ? math.sin(clock.value * 2 * math.pi) * 3 : 0.0;
    canvas.drawImageRect(sheet, src, (Offset(0, dy) & size), _paint);
  }

  @override
  bool shouldRepaint(_SpinPainter o) => o.sheet != sheet || o.bob != bob;
}

/// Podium, floor shadow and the soft spotlight, lit by [reveal].
class _StagePainter extends CustomPainter {
  _StagePainter({
    required super.repaint,
    required this.reveal,
    required this.burst,
    required this.colors,
    required this.surface,
    required this.edge,
    required this.ink,
    required this.reduce,
  });

  final Animation<double> reveal, burst;
  final List<Color> colors;
  final Color surface, edge, ink;
  final bool reduce;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final lit = Curves.easeOut.transform(reveal.value);
    final top = Offset(cx, size.height - 52), rx = 108.0, ry = 24.0;
    final tint = colors.first;

    // Floor shadow.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, size.height - 20), width: 290, height: 34),
      Paint()
        ..color = ink.withValues(alpha: .16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Spotlight cone from above, then the pool of light on the podium.
    if (lit > 0) {
      final cone = Path()
        ..moveTo(cx - 26, 0)
        ..lineTo(cx + 26, 0)
        ..lineTo(cx + rx + 20, top.dy)
        ..lineTo(cx - rx - 20, top.dy)
        ..close();
      canvas.drawPath(
        cone,
        Paint()
          ..shader = ui.Gradient.linear(Offset(cx, 0), top, [
            tint.withValues(alpha: 0),
            tint.withValues(alpha: .24 * lit),
          ])
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }

    // Podium: side wall, then the lit top.
    final bottom = top.translate(0, 24);
    final side = Path()
      ..moveTo(top.dx - rx, top.dy)
      ..lineTo(bottom.dx - rx, bottom.dy)
      ..arcTo(Rect.fromCenter(center: bottom, width: rx * 2, height: ry * 2),
          math.pi, -math.pi, false)
      ..lineTo(top.dx + rx, top.dy)
      ..close();
    final wall = Color.lerp(surface, ink, .12)!;
    canvas.drawPath(side, Paint()..color = wall);
    canvas.drawPath(
        side,
        Paint()
          ..shader = ui.Gradient.linear(Offset(top.dx - rx, 0), Offset(top.dx + rx, 0),
              [Colors.black.withValues(alpha: .12), Colors.transparent, Colors.black.withValues(alpha: .18)],
              [0, .5, 1]));
    final topOval = Rect.fromCenter(center: top, width: rx * 2, height: ry * 2);
    canvas.drawOval(topOval, Paint()..color = Color.lerp(surface, tint, .18 * lit)!);
    // Pool of light.
    canvas.drawOval(
      topOval.deflate(10),
      Paint()
        ..shader = ui.Gradient.radial(top, rx, [
          tint.withValues(alpha: .55 * lit),
          tint.withValues(alpha: 0),
        ]),
    );
    // Lit rim.
    canvas.drawOval(
      topOval,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Color.lerp(edge, tint, lit)!,
    );
    if (lit > 0) {
      canvas.drawOval(
        topOval,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = tint.withValues(alpha: .35 * lit)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    // Landing shockwave.
    final b = burst.value;
    if (!reduce && b > 0 && b < 1) {
      final e = Curves.easeOut.transform(b);
      canvas.drawOval(
        Rect.fromCenter(center: top, width: (rx * 2) * (1 + e * .7), height: (ry * 2) * (1 + e * .7)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 * (1 - e)
          ..color = tint.withValues(alpha: .7 * (1 - e)),
      );
    }
  }

  @override
  bool shouldRepaint(_StagePainter o) =>
      o.colors != colors || o.surface != surface || o.reduce != reduce;
}

/// Sparkles rising off the podium in the landmark's colours.
class _SparklePainter extends CustomPainter {
  _SparklePainter({
    required this.clock,
    required this.reveal,
    required this.colors,
  }) : super(repaint: clock);

  final Animation<double> clock, reveal;
  final List<Color> colors;

  static const _n = 22;
  static final _seeds = () {
    final r = math.Random(7);
    return [for (var i = 0; i < _n; i++) List.generate(5, (_) => r.nextDouble())];
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final base = size.height - 58;
    final p = Paint();
    for (var i = 0; i < _n; i++) {
      final s = _seeds[i];
      final life = (clock.value * (1 + (i % 3)) + s[0]) % 1;
      final x = cx + (s[1] - .5) * 230 + math.sin(life * 6 + s[2] * 6) * 8;
      final y = base - life * (130 + s[3] * 70);
      final a = math.sin(math.pi * life) * reveal.value;
      final r = 2.2 + s[4] * 3.2;
      p.color = colors[i % colors.length].withValues(alpha: a * .95);
      final path = Path()
        ..moveTo(x, y - r * 1.6)
        ..quadraticBezierTo(x, y, x + r * 1.6, y)
        ..quadraticBezierTo(x, y, x, y + r * 1.6)
        ..quadraticBezierTo(x, y, x - r * 1.6, y)
        ..quadraticBezierTo(x, y, x, y - r * 1.6);
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter o) => o.colors != colors;
}
