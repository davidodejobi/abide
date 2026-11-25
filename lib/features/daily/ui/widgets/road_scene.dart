import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';

import '../../domain/reading_plan.dart';
import '../../domain/road_geometry.dart';
import '../../domain/road_landmarks.dart';
import '../daily_strings.dart';
import 'road_art.dart';

enum RoadMood { day, evening }

/// The living road on the Today tab: a winding road of day stops over soft
/// parallax layers (sky, far hills, meadow, road), Blender-rendered props and
/// Bible landmarks beside it, and a traveller who walks from stop to stop with
/// the camera following when a day is read.
///
/// Drawn with one [CustomPainter] on plain Flutter animation: a handful of
/// cached images and no per-frame image or shader work while idle, which keeps
/// 60 fps on a mid phone without pulling in a game engine for a single scene.
///
/// [currentDay] is the stop the traveller stands on and that glows (today's
/// reading, or tomorrow's once today is done); null when the plan is finished.
/// With reduced motion the walk is replaced by a cut and a short fade.
class RoadScene extends StatefulWidget {
  const RoadScene({
    super.key,
    required this.width,
    required this.mood,
    required this.currentDay,
    required this.totalDays,
    this.plan,
    this.showTomorrowTag = false,
  });

  final double width;
  final RoadMood mood;

  /// Day number at the glowing stop; null when the plan is finished.
  final int? currentDay;
  final int totalDays;

  /// Used to place landmarks by passage; null draws the road without them.
  final ReadingPlan? plan;
  final bool showTomorrowTag;

  static const double designWidth = 390;
  static const double designHeight = 560;

  static double heightFor(double width) => width * designHeight / designWidth;

  @override
  State<RoadScene> createState() => RoadSceneState();
}

const _walkTime = Duration(milliseconds: 2600);
const _duskTime = Duration(milliseconds: 900);

@visibleForTesting
class RoadSceneState extends State<RoadScene>
    with TickerProviderStateMixin {
  late final AnimationController _walk =
      AnimationController(vsync: this, duration: _walkTime);
  // 96 s so the 2.4 s pulse and the cloud drift both wrap without a jump.
  late final AnimationController _ambient =
      AnimationController(vsync: this, duration: const Duration(seconds: 96));
  late final AnimationController _fade = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 240), value: 1);
  final _cache = _Cache();

  RoadArt? _art;
  Map<int, Landmark> _landmarks = const {};
  String? _landmarkPlan;

  late double _from, _to, _dusk0, _dusk1;
  bool _pending = false;
  bool _reduce = false;
  String? _selected;

  double get _target =>
      (widget.currentDay ?? widget.totalDays).toDouble();
  double get _duskTarget => widget.mood == RoadMood.evening ? 1 : 0;

  @override
  void initState() {
    super.initState();
    _from = _to = _target;
    _dusk0 = _dusk1 = _duskTarget;
    RoadArt.load().then((a) {
      if (!mounted) return;
      setState(() {
        _art = a;
        _syncLandmarks();
      });
    }, onError: (_) {});
  }

  void _syncLandmarks() {
    final plan = widget.plan;
    if (_art == null || plan == null) {
      _landmarks = const {};
      _landmarkPlan = null;
    } else if (_landmarkPlan != plan.id) {
      _landmarks = landmarksByDay(plan, _art!.landmarks);
      _landmarkPlan = plan.id;
      _art!.ensureLandmarks(_landmarks.values.map((l) => l.art)).then((_) {
        if (mounted) setState(() {});
      }, onError: (_) {});
    }
  }

  /// The traveller's current fractional stop position, for tests.
  @visibleForTesting
  double get debugPos => _posNow;

  /// Whether the ambient loop is running, for tests.
  @visibleForTesting
  bool get debugAmbientRunning => _ambient.isAnimating;

  double get _posNow => _from + (_to - _from) * Curves.easeInOutCubic.transform(_walk.value);
  double get _duskNow => _dusk0 + (_dusk1 - _dusk0) * _walk.value;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce != _reduce || !_ambient.isAnimating) {
      _reduce = reduce;
      if (reduce) {
        _ambient.stop();
      } else if (!_ambient.isAnimating) {
        _ambient.repeat();
      }
    }
    _maybeStart();
  }

  @override
  void didUpdateWidget(RoadScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncLandmarks();
    final target = _target, dusk = _duskTarget;
    if (target == _to && dusk == _dusk1) return;
    final here = _posNow, duskHere = _duskNow;
    _walk.stop();
    _from = here;
    _to = target;
    _dusk0 = duskHere;
    _dusk1 = dusk;
    _walk.value = 0;
    final distance = (target - here).abs();
    if (_reduce || distance > 3) {
      // Reduced motion, or a jump too long to walk (plan switch, undo): cut to
      // the final state under a short fade.
      _from = _to;
      _dusk0 = _dusk1;
      _walk.value = 1;
      _fade.forward(from: 0);
      _pending = false;
      return;
    }
    _walk.duration = distance == 0 ? _duskTime : _walkTime;
    _pending = true;
    _maybeStart();
  }

  /// Starts a queued walk once the tab is on screen: the Today tab stays alive
  /// off screen, and a walk run there would be over before it is seen.
  void _maybeStart() {
    if (!_pending || !TickerMode.of(context)) return;
    _pending = false;
    _walk.forward(from: 0);
  }

  @override
  void dispose() {
    _walk.dispose();
    _ambient.dispose();
    _fade.dispose();
    super.dispose();
  }

  void _onTap(TapUpDetails d) {
    final k = widget.width / RoadScene.designWidth;
    final p = d.localPosition / k;
    String? hit;
    for (final h in _cache.hits) {
      if (h.rect.contains(p)) hit = h.landmark.id;
    }
    setState(() => _selected = hit == _selected ? null : hit);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final painter = _RoadPainter(
      repaint: Listenable.merge([_walk, _ambient]),
      c: c,
      dark: dark,
      art: _art,
      cache: _cache,
      walk: _walk,
      ambient: _ambient,
      from: _from,
      to: _to,
      dusk0: _dusk0,
      dusk1: _dusk1,
      total: widget.totalDays,
      finished: widget.currentDay == null,
      landmarks: _landmarks,
      selected: _selected,
      showTomorrowTag: widget.showTomorrowTag && widget.currentDay != null,
      semantics: _semantics,
    );
    return SizedBox(
      width: widget.width,
      height: RoadScene.heightFor(widget.width),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        excludeFromSemantics: true,
        onTapUp: _onTap,
        child: FadeTransition(
          opacity: _fade,
          child: CustomPaint(painter: painter),
        ),
      ),
    );
  }

  /// One node for the traveller's stop and one per landmark in view, placed
  /// for the final (not mid-walk) camera so a screen reader sees a steady map.
  List<CustomPainterSemantics> _semantics(Size size, _RoadPainter p) {
    final k = size.width / RoadScene.designWidth;
    final cam = p.camera(_to);
    final out = <CustomPainterSemantics>[];
    final day = widget.currentDay;
    if (day != null) {
      final s = p.geo.stop(day);
      final c = Offset(s.x + cam.dx, s.y + cam.dy) * k;
      out.add(CustomPainterSemantics(
        rect: Rect.fromCenter(center: c, width: 70 * k, height: 50 * k),
        properties: SemanticsProperties(
          textDirection: TextDirection.ltr,
          label: widget.showTomorrowTag
              ? DailyStrings.tomorrowDay(day)
              : DailyStrings.dayN(day),
          sortKey: const OrdinalSortKey(0),
        ),
      ));
    }
    final first = _to.floor() - 2;
    for (var n = first; n <= first + 9; n++) {
      final lm = _landmarks[n];
      if (lm == null) continue;
      final r = p.landmarkRect(n, cam);
      // Only what is visible above the reading panel (it starts near 392).
      if (r.center.dy < 0 || r.center.dy > 380) continue;
      out.add(CustomPainterSemantics(
        rect: Rect.fromLTRB(r.left * k, r.top * k, r.right * k, r.bottom * k),
        properties: SemanticsProperties(
          textDirection: TextDirection.ltr,
          label: '${lm.title}, ${lm.ref}',
          button: true,
          onTap: () => setState(() => _selected = lm.id),
        ),
      ));
    }
    return out;
  }
}

class _Hit {
  _Hit(this.rect, this.landmark, this.n);
  final Rect rect;
  final Landmark landmark;
  final int n;
}

/// Things that outlive a painter instance: shaders, paints, text layouts.
class _Cache {
  final hits = <_Hit>[];
  final text = <String, TextPainter>{};
  final filters = <int, ColorFilter>{};
  final sprite = Paint()..filterQuality = FilterQuality.medium;
  final fill = Paint();
  final stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final glow = Paint();
  final shadow = Paint()..color = const Color(0x33000000);

  bool? dark;
  double? dusk;
  Paint? skyPaint, groundPaint, mistPaint;
  Shader? glowShader;
  Color? glowShaderColor;

  Path? road;
  int roadFrom = -999;
  bool facingRight = false;

  ColorFilter filter(Color tint) =>
      filters.putIfAbsent(tint.toARGB32(), () => ColorFilter.mode(tint, BlendMode.modulate));
}

const double _s = 30 / 96; // design px per sprite px (96 px per world unit)
const _coin = Offset(153, 124); // coin top-face centre in stop_*.webp
const _foot = Offset(124, 238); // between the feet in a trav cell
const _cellW = 249.0, _cellH = 316.0, _cols = 7;
const _propScale = {
  'prop_tree': .6, 'prop_cypress': .6, 'prop_bush': .62, 'prop_pond': .8,
  'prop_flowers': .65, 'prop_rock': .6,
};
const _propKinds = [
  'prop_tree', 'prop_bush', 'prop_cypress', 'prop_pond', 'prop_flowers',
  'prop_rock', 'prop_tree', 'prop_bush',
];
const _landmarkScale = .5;
const _focusY = 300.0;

class _RoadPainter extends CustomPainter {
  _RoadPainter({
    required Listenable repaint,
    required this.c,
    required this.dark,
    required this.art,
    required this.cache,
    required this.walk,
    required this.ambient,
    required this.from,
    required this.to,
    required this.dusk0,
    required this.dusk1,
    required this.total,
    required this.finished,
    required this.landmarks,
    required this.selected,
    required this.showTomorrowTag,
    required this.semantics,
  }) : super(repaint: repaint);

  final LumColors c;
  final bool dark;
  final RoadArt? art;
  final _Cache cache;
  final AnimationController walk, ambient;
  final double from, to, dusk0, dusk1;
  final int total;
  final bool finished, showTomorrowTag;
  final Map<int, Landmark> landmarks;
  final String? selected;
  final geo = const RoadGeometry();
  final List<CustomPainterSemantics> Function(Size, _RoadPainter) semantics;

  @override
  SemanticsBuilderCallback get semanticsBuilder => (size) => semantics(size, this);

  /// Screen offset to add to a world point so that stop position [pos] sits at
  /// the focus point. The camera follows the walker fully in y and a third of
  /// the way in x, so the swinging road stays on screen.
  Offset camera(double pos) {
    final p = geo.at(pos + .25);
    return Offset(195 - p.x * .3, _focusY - p.y);
  }

  Offset _stopAt(int n, Offset cam) {
    final s = geo.stop(n);
    return Offset(s.x + cam.dx, s.y + cam.dy);
  }

  /// Where landmark [n] stands, in design pixels: outboard of its own stop so
  /// it never sits on the road.
  Rect landmarkRect(int n, Offset cam, [double r = 1]) {
    final s = _stopAt(n, cam);
    final side = geo.stop(n).x > 0 ? 1.0 : -1.0;
    const w = 672 * _s * _landmarkScale, h = 576 * _s * _landmarkScale;
    final cx = s.dx + side * 78, bottom = s.dy + 18 - (1 - r) * 0;
    return Rect.fromLTWH(cx - w / 2, bottom - h * .86, w, h);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / RoadScene.designWidth;
    canvas.save();
    canvas.scale(k);
    canvas.clipRect(const Rect.fromLTWH(0, 0, 390, 560));

    final t = Curves.easeInOutCubic.transform(walk.value);
    final pos = from + (to - from) * t;
    final dusk = dusk0 + (dusk1 - dusk0) * walk.value;
    final moving = walk.status == AnimationStatus.forward && from != to;
    final secs = ambient.value * 96;
    final pulse = .5 + .5 * math.sin(secs * 2 * math.pi / 2.4);
    final cam = camera(pos);
    final tint = _tint(dusk);
    final sp = cache.sprite..colorFilter = cache.filter(tint);
    cache.hits.clear();

    _background(canvas, dusk);
    _clouds(canvas, sp, secs, cam);
    final hills = art?['hills'];
    if (hills != null) {
      const w = 640.0, h = w * 480 / 2496;
      sp.color = const Color(0xD9FFFFFF);
      canvas.drawImageRect(
          hills,
          Rect.fromLTWH(0, 0, hills.width.toDouble(), hills.height.toDouble()),
          Rect.fromLTWH(195 - w / 2 - cam.dx * .06, 150 + (cam.dy - 100) * .05 - h, w, h),
          sp);
      sp.color = const Color(0xFFFFFFFF);
    }
    _ground(canvas, dusk, cam);
    _road(canvas, pos, dusk, cam);
    _worldSprites(canvas, sp, pos, cam, pulse, dusk, tint);
    _mist(canvas, dusk);
    _traveller(canvas, sp, pos, cam, moving);
    _labels(canvas, pos, cam);
    canvas.restore();
  }

  // ------------------------------------------------------------------ colour
  Color _tint(double dusk) {
    var t = Color.lerp(const Color(0xFFFFFFFF), const Color(0xFFC8B8E0), dusk * .55)!;
    if (dark) t = Color.lerp(t, const Color(0xFF8E9AB8), .8)!;
    return t;
  }

  Color _l(Color a, Color b, double dusk) => Color.lerp(a, b, dusk)!;

  void _background(Canvas canvas, double dusk) {
    final top = _l(c.sceneSkyTop, c.sceneDuskSkyTop, dusk);
    final mid = _l(c.sceneSkyMid, c.sceneDuskSkyMid, dusk);
    final hor = _l(c.sceneSkyHorizon, c.sceneDuskSkyHorizon, dusk);
    final settled = dusk == 0 || dusk == 1;
    if (!(settled && cache.dusk == dusk && cache.dark == dark && cache.skyPaint != null)) {
      cache.skyPaint = Paint()
        ..shader = ui.Gradient.linear(Offset.zero, const Offset(0, 330), [top, mid, hor], [0, .55, 1]);
      final land = _l(c.sceneMeadowTop, c.sceneDuskLand, dusk);
      final landLow = _l(c.sceneMeadowBottom, c.sceneDuskLand, dusk);
      final clear = land.withValues(alpha: 0);
      cache.groundPaint = Paint()
        ..shader = ui.Gradient.linear(const Offset(0, 120), const Offset(0, 560), [clear, land, landLow], [0, .2, 1]);
      cache.mistPaint = Paint()
        ..shader = ui.Gradient.linear(const Offset(0, 40), const Offset(0, 215),
            [hor.withValues(alpha: .96), hor.withValues(alpha: 0)]);
      cache.dusk = settled ? dusk : null;
      cache.dark = dark;
    }
    canvas.drawRect(const Rect.fromLTWH(0, 0, 390, 560), cache.skyPaint!);
  }

  void _clouds(Canvas canvas, Paint sp, double secs, Offset cam) {
    final cloud = art?['cloud'];
    if (cloud == null) return;
    final src = Rect.fromLTWH(0, 0, cloud.width.toDouble(), cloud.height.toDouble());
    sp.color = const Color(0xCCFFFFFF);
    for (var i = 0; i < 3; i++) {
      final x = ((secs * (5 + i * 2) + i * 200) % 576) - 120;
      final y = 46.0 + i * 34 + (cam.dy - 100) * .03;
      final w = (170 - i * 28).toDouble();
      canvas.drawImageRect(cloud, src, Rect.fromLTWH(x, y, w, w * 0.48), sp);
    }
    sp.color = const Color(0xFFFFFFFF);
  }

  int _hash(int n) {
    var h = (n * 0x45d9f3b) & 0xffffffff;
    h = ((h >> 16) ^ h) * 0x45d9f3b & 0xffffffff;
    return (h >> 16) ^ h;
  }

  void _ground(Canvas canvas, double dusk, Offset cam) {
    canvas.drawRect(const Rect.fromLTWH(0, 120, 390, 440), cache.groundPaint!);
    final base = _l(c.sceneMeadowTop, c.sceneDuskLand, dusk);
    const row = 96.0;
    final j0 = ((120 - cam.dy) / row).floor(), j1 = ((580 - cam.dy) / row).ceil();
    final f = cache.fill;
    for (var j = j0; j <= j1; j++) {
      final h = _hash(j + 1000);
      final wx = (h % 300) - 150.0 + (j.isEven ? 60 : -60);
      final wy = j * row + (h >> 8) % 40;
      final r = 46.0 + (h >> 4) % 44;
      f.color = (h.isEven
              ? Color.lerp(base, const Color(0xFFFFFFFF), .18)!
              : Color.lerp(base, const Color(0xFF1B5E2A), .14)!)
          .withValues(alpha: .32);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(wx + cam.dx * .98 + 0, wy + cam.dy), width: r * 2.2, height: r * 1.2), f);
    }
  }

  void _road(Canvas canvas, double pos, double dusk, Offset cam) {
    final w0 = math.max(0, pos.floor() - 3);
    if (cache.road == null || cache.roadFrom != w0) {
      final p = Path();
      const steps = 10;
      for (var i = 0; i <= 14 * steps; i++) {
        final q = geo.at(w0 + i / steps);
        i == 0 ? p.moveTo(q.x, q.y) : p.lineTo(q.x, q.y);
      }
      cache.road = p;
      cache.roadFrom = w0;
    }
    canvas.save();
    canvas.translate(cam.dx, cam.dy);
    final s = cache.stroke;
    s.strokeWidth = 30;
    s.color = _l(c.sceneRoadEdge, c.sceneDuskLand, dusk * .4);
    canvas.drawPath(cache.road!, s);
    s.strokeWidth = 23;
    s.color = _l(c.sceneRoad, dark ? c.sceneDuskLand : const Color(0xFFD9CDE6), dusk * .6);
    canvas.drawPath(cache.road!, s);
    canvas.restore();
  }

  // ----------------------------------------------- props, stops, landmarks
  void _worldSprites(Canvas canvas, Paint sp, double pos, Offset cam, double pulse, double dusk, Color tint) {
    final nMax = ((cam.dy - 120) / geo.spacing).ceil() + 1; // stops above the horizon cut-off
    final nMin = ((cam.dy - 580) / geo.spacing).floor() - 1;
    for (var n = nMax; n >= nMin; n--) {
      _props(canvas, sp, n, cam);
      if (n < 1 || n > total) continue;
      final lm = landmarks[n];
      if (lm != null) _landmark(canvas, sp, n, lm, pos, cam, pulse, tint);
      _stop(canvas, sp, n, pos, cam, pulse, dusk);
    }
  }

  void _props(Canvas canvas, Paint sp, int n, Offset cam) {
    final h = _hash(n + 77);
    final side = geo.stop(n).x > 0 ? -1.0 : 1.0;
    final kind = _propKinds[h % _propKinds.length];
    final img = art?[kind];
    if (img == null) return;
    final lmSide = landmarks[n] != null ? (geo.stop(n).x > 0 ? 1.0 : -1.0) : 0.0;
    final s = _stopAt(n, cam);
    var dx = side * (118 + (h >> 4) % 46).toDouble();
    if (lmSide != 0 && dx.sign == lmSide) dx = -dx;
    final sc = (_propScale[kind] ?? .6) * _s;
    final w = img.width * sc, hh = img.height * sc;
    final cx = dx + cam.dx;
    final bottom = s.dy + 26 + (h >> 9) % 20;
    sp.color = const Color(0xFFFFFFFF);
    canvas.drawImageRect(img, Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        Rect.fromLTWH(cx - w / 2, bottom - hh + 6, w, hh), sp);
  }

  void _stop(Canvas canvas, Paint sp, int n, double pos, Offset cam, double pulse, double dusk) {
    final lock = art?['stop_lock'], done = art?['stop_done'], cur = art?['stop_cur'];
    final s = _stopAt(n, cam);
    if (s.dy < 20 || s.dy > 640) return;
    final isDone = finished ? true : pos > n + .0001;
    final base = isDone ? done : lock;
    final dst = Rect.fromLTWH(s.dx - _coin.dx * _s, s.dy - _coin.dy * _s,
        307 * _s, 249 * _s);
    if (base != null) {
      canvas.drawImageRect(base, Rect.fromLTWH(0, 0, base.width.toDouble(), base.height.toDouble()), dst, sp);
    }
    final g = finished ? 0.0 : (1 - (pos - n).abs() * 1.6).clamp(0.0, 1.0);
    if (g > 0 && cur != null) {
      sp.color = Color.fromRGBO(255, 255, 255, g);
      canvas.drawImageRect(cur, Rect.fromLTWH(0, 0, cur.width.toDouble(), cur.height.toDouble()), dst, sp);
      sp.color = const Color(0xFFFFFFFF);
      final ring = cache.stroke
        ..strokeWidth = 2.4
        ..color = c.sceneGlow.withValues(alpha: g * (.35 + .5 * pulse));
      canvas.drawOval(
          Rect.fromCenter(center: Offset(s.dx, s.dy + 2), width: 78 + 12 * pulse, height: 48 + 8 * pulse), ring);
    }
    final label = _text('n$n${g > .5 || isDone ? 'c' : 'u'}', '$n',
        LumText.roadDisplayStat28.copyWith(
            fontSize: n > 99 ? 14 : 17,
            height: 1,
            color: (g > .5 || isDone) ? c.sceneStopOnCurrent : c.sceneStopOnUpcoming));
    label.paint(canvas, Offset(s.dx - label.width / 2, s.dy - label.height / 2 - 4));
  }

  void _landmark(Canvas canvas, Paint sp, int n, Landmark lm, double pos, Offset cam, double pulse, Color tint) {
    final img = art?['lm_${lm.art}'];
    if (img == null) return;
    // Reveal as the walker closes in on the stop: it rises, warms and glows.
    final r = Curves.easeOut.transform(((pos - (n - .55)) / .55).clamp(0.0, 1.0));
    final rect = landmarkRect(n, cam);
    if (rect.bottom < 40 || rect.top > 600) return;
    final shifted = rect.shift(Offset(0, (1 - r) * 14));
    cache.hits.add(_Hit(rect, lm, n));
    if (r > .02) {
      final burst = math.sin(math.pi * ((pos - (n - .3)) / .9).clamp(0.0, 1.0));
      final a = (r * (.5 + .25 * pulse) + burst * .3).clamp(0.0, 1.0);
      final col = c.sceneGlow;
      if (cache.glowShader == null || cache.glowShaderColor != col) {
        cache.glowShader = ui.Gradient.radial(Offset.zero, 70, [col, col.withValues(alpha: 0)]);
        cache.glowShaderColor = col;
      }
      canvas.save();
      canvas.translate(shifted.center.dx, shifted.center.dy + 6);
      cache.glow
        ..shader = cache.glowShader
        ..color = Color.fromRGBO(255, 255, 255, a);
      canvas.drawCircle(Offset.zero, 70, cache.glow);
      canvas.restore();
    }
    sp.colorFilter = cache.filter(Color.lerp(const Color(0xFFB4BCD0), tint, r)!);
    sp.color = Color.fromRGBO(255, 255, 255, .42 + .58 * r);
    final grown = Rect.fromCenter(
        center: shifted.center, width: shifted.width * (.9 + .1 * r), height: shifted.height * (.9 + .1 * r));
    canvas.drawImageRect(img, Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()), grown, sp);
    sp.color = const Color(0xFFFFFFFF);
    sp.colorFilter = cache.filter(tint);
  }

  void _mist(Canvas canvas, double dusk) {
    canvas.drawRect(const Rect.fromLTWH(0, 0, 390, 215), cache.mistPaint!);
  }

  // -------------------------------------------------------------- traveller
  void _traveller(Canvas canvas, Paint sp, double pos, Offset cam, bool moving) {
    final p = geo.at(pos);
    final x = p.x + cam.dx, y = p.y + cam.dy;
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y + 4), width: 34, height: 11), cache.shadow);
    final sheet = art?['trav'];
    if (sheet == null) return;
    var frame = 12;
    if (moving) {
      final q = geo.at(pos + .02);
      if ((q.x - p.x).abs() > .001) cache.facingRight = q.x > p.x;
      frame = ((pos - from).abs() / .4 * 12).floor() % 12;
    } else {
      // Standing: face the way the next stop lies.
      final next = geo.stop((pos.round() + 1)).x - geo.stop(pos.round()).x;
      cache.facingRight = next > 0;
    }
    final col = frame % _cols, row = frame ~/ _cols;
    final src = Rect.fromLTWH(col * _cellW, row * _cellH, _cellW, _cellH);
    const w = _cellW * _s, h = _cellH * _s;
    canvas.save();
    canvas.translate(x, y + 2);
    // The sprite looks left; mirror it to face right.
    if (cache.facingRight) canvas.scale(-1, 1);
    sp.color = const Color(0xFFFFFFFF);
    canvas.drawImageRect(sheet, src, Rect.fromLTWH(-_foot.dx * _s, -_foot.dy * _s, w, h), sp);
    canvas.restore();
  }

  // ------------------------------------------------------------ text chips
  TextPainter _text(String key, String text, TextStyle style, {double maxWidth = double.infinity}) {
    return cache.text.putIfAbsent(
        '${dark ? 'd' : 'l'}$key',
        () => TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: TextDirection.ltr,
            textScaler: TextScaler.noScaling,
            maxLines: 1,
            ellipsis: '…')
          ..layout(maxWidth: maxWidth));
  }

  void _chip(Canvas canvas, Offset anchorBottomCenter, TextPainter tp, double alpha) {
    final w = tp.width + 20;
    final cx = anchorBottomCenter.dx.clamp(8 + w / 2, 382 - w / 2).toDouble();
    final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, anchorBottomCenter.dy - 12), width: w, height: tp.height + 10),
        const Radius.circular(LumRadius.full));
    cache.fill.color = c.scenePanel.withValues(alpha: alpha);
    canvas.drawRRect(r, cache.fill);
    final s = cache.stroke
      ..strokeWidth = 1
      ..color = c.borderSubtle.withValues(alpha: alpha);
    canvas.drawRRect(r, s);
    tp.paint(canvas, r.center.translate(-tp.width / 2, -tp.height / 2));
  }

  void _labels(Canvas canvas, double pos, Offset cam) {
    final settled = walk.value == 0 || walk.value == 1;
    for (final h in cache.hits) {
      final here = settled && (pos - h.n).abs() < .01;
      if (selected != h.landmark.id && !here) continue;
      final tp = _text('lm${h.landmark.id}', '${h.landmark.short} · ${h.landmark.ref}',
          LumText.caption.copyWith(color: c.textPrimary, fontWeight: FontWeight.w600),
          maxWidth: 220);
      _chip(canvas, Offset(h.rect.center.dx, h.rect.top + 8), tp, 1);
    }
    if (showTomorrowTag && settled) {
      final s = _stopAt(to.round(), cam);
      final tp = _text('tomorrow', DailyStrings.tomorrow,
          LumText.caption.copyWith(color: c.textPrimary, fontWeight: FontWeight.w600));
      _chip(canvas, Offset(s.dx, s.dy - 40), tp, 1);
    }
  }

  @override
  bool shouldRepaint(_RoadPainter o) => true;
}
