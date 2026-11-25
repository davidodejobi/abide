import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';

import '../../domain/reading_plan.dart';
import '../../domain/road_days.dart';
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
///
/// Drag the scene to explore: the camera leaves the traveller and runs up (or
/// back down) the road to any day of the plan, with momentum, while a "Back to
/// today" pill brings it home. Tap a stop or a landmark for [onStopTap] /
/// [onLandmarkTap].
class RoadScene extends StatefulWidget {
  const RoadScene({
    super.key,
    required this.width,
    required this.mood,
    required this.currentDay,
    required this.totalDays,
    this.plan,
    this.showTomorrowTag = false,
    this.height,
    this.visibleBottom,
    this.hideBack,
    this.onStopTap,
    this.onLandmarkTap,
  });

  /// The scene's height; defaults to the design aspect ([heightFor]). The
  /// Today tab gives it the whole screen so the road can fill it.
  final double? height;

  /// Where the reading panel's top edge is, in px from the scene's top, as it
  /// slides. The camera keeps the traveller at the same share of the visible
  /// road above it, so the scene resizes smoothly with the panel. Null: the
  /// panel sits at its design position.
  final ValueListenable<double>? visibleBottom;

  /// True while the panel covers the top of the scene: "Back to today"
  /// would sit under the greeting, so it hides.
  final ValueListenable<bool>? hideBack;

  /// Called with the day number of a tapped stop.
  final void Function(int day)? onStopTap;

  /// Called with a tapped landmark and the day it stands at.
  final void Function(Landmark landmark, int day)? onLandmarkTap;

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
class RoadSceneState extends State<RoadScene> with TickerProviderStateMixin {
  late final AnimationController _walk =
      AnimationController(vsync: this, duration: _walkTime);
  // 96 s so the 2.4 s pulse and the cloud drift both wrap without a jump.
  late final AnimationController _ambient =
      AnimationController(vsync: this, duration: const Duration(seconds: 96));
  late final AnimationController _fade = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 240), value: 1);
  // Explore: a fling in stop units, the glide home, and a nudge that repaints
  // the scene while dragging (the ambient loop is off under reduced motion).
  late final AnimationController _glide =
      AnimationController.unbounded(vsync: this)
        ..addListener(_onGlide)
        ..addStatusListener(_onGlideStatus);
  late final AnimationController _back = AnimationController(vsync: this)
    ..addStatusListener(_onBackStatus);
  final _nudge = ValueNotifier<int>(0);
  final _cache = _Cache();
  static const _geo = RoadGeometry();

  RoadArt? _art;
  Map<int, List<Landmark>> _landmarks = const {};
  int? _windowAt; // stop the loaded landmark sprites are centred on
  String? _landmarkPlan;

  late double _from, _to, _dusk0, _dusk1;
  bool _pending = false;
  bool _reduce = false;

  /// The camera's stop position while exploring; null while it follows the
  /// traveller. During the glide home it is where the glide started.
  double? _exploreAt;
  bool _showBack = false;

  double get _target => (widget.currentDay ?? widget.totalDays).toDouble();
  double get _duskTarget => widget.mood == RoadMood.evening ? 1 : 0;

  @override
  void initState() {
    super.initState();
    _from = _to = _target;
    _dusk0 = _dusk1 = _duskTarget;
    widget.visibleBottom?.addListener(_panelMoved);
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
      _landmarks = landmarksByDay(plan, _art!.landmarks, placeArtless: true);
      _landmarkPlan = plan.id;
      _windowAt = null;
      _syncWindow(_lookNow());
    }
  }

  /// Sprites are decoded only for landmarks within [_windowStops] of the
  /// camera and evicted beyond (a year-long plan would otherwise hold every
  /// picture for ever). Re-centred once the camera is [_windowStep] stops from
  /// the last centre; until a sprite is in, its landmark shows as a signpost.
  static const _windowStops = 15, _windowStep = 5;

  void _syncWindow(double look) {
    final art = _art;
    if (art == null) return;
    final at = look.round();
    if (_windowAt != null && (at - _windowAt!).abs() < _windowStep) return;
    _windowAt = at;
    art.ensureLandmarks([
      for (var n = at - _windowStops; n <= at + _windowStops; n++)
        for (final l in _landmarks[n] ?? const <Landmark>[]) l.art,
    ]).then((_) {
      if (mounted) setState(() {});
    }, onError: (_) {});
  }

  /// The traveller's current fractional stop position, for tests.
  @visibleForTesting
  double get debugPos => _posNow;

  /// Whether the ambient loop is running, for tests.
  @visibleForTesting
  bool get debugAmbientRunning => _ambient.isAnimating;

  /// The stop position the camera is at, for tests.
  @visibleForTesting
  double get debugLook => _lookNow();

  /// Where to tap (local px) to hit the landmark at [day], for tests.
  @visibleForTesting
  Offset? debugLandmarkTap(int day, [int slot = 0]) {
    final list = _landmarks[day];
    if (list == null || slot >= list.length) return null;
    final r = _RoadPainter.landmarkRect(day, _cameraAt(_lookNow()), slot);
    return r.center.translate(0, 8) * (widget.width / RoadScene.designWidth);
  }

  /// Whether the camera has left the traveller, for tests.
  @visibleForTesting
  bool get debugExploring => _exploreAt != null;

  double get _posNow =>
      _from + (_to - _from) * Curves.easeInOutCubic.transform(_walk.value);
  double get _duskNow => _dusk0 + (_dusk1 - _dusk0) * _walk.value;

  /// Where the camera looks: the traveller's position, unless exploring.
  double _lookNow() {
    final at = _exploreAt;
    if (at == null) return _posNow;
    if (!_back.isAnimating) return at;
    return at + (_posNow - at) * Curves.easeInOutCubic.transform(_back.value);
  }

  double get _pxPerStop => widget.width / RoadScene.designWidth * _geo.spacing;

  // ------------------------------------------------------------------ explore
  void _dragStart(DragStartDetails d) {
    _glide.stop();
    _exploreAt = _lookNow();
    _back.stop();
    _back.value = 0;
  }

  void _dragUpdate(DragUpdateDetails d) {
    // Dragging down moves the world down, so the road ahead comes into view.
    _moveTo(_exploreAt! + d.delta.dy / _pxPerStop);
  }

  void _dragEnd(DragEndDetails d) {
    // The simulation runs in pixels (its constants are tuned for them); the
    // glide listener converts back to stops.
    final v = d.velocity.pixelsPerSecond.dy;
    if (_reduce || v.abs() < 150) {
      setState(() {});
      return;
    }
    final at = _exploreAt! * _pxPerStop;
    _glide.value = at;
    _glide.animateWith(ClampingScrollSimulation(position: at, velocity: v));
  }

  void _moveTo(double look) {
    final c = clampLook(look, widget.totalDays);
    _exploreAt = c;
    _syncWindow(c);
    final far = (c - _posNow).abs() > 1.2;
    if (far != _showBack) {
      setState(() => _showBack = far);
    }
    _nudge.value++;
  }

  void _onGlide() {
    if (_exploreAt == null || _back.isAnimating) return;
    final v = _glide.value / _pxPerStop;
    _moveTo(v);
    if (v <= 0 || v >= widget.totalDays) {
      _glide.stop();
      setState(() {});
    }
  }

  void _onGlideStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed && mounted) setState(() {});
  }

  void _onBackStatus(AnimationStatus s) {
    if (s != AnimationStatus.completed) return;
    setState(() {
      _exploreAt = null;
      _showBack = false;
    });
    _syncWindow(_posNow);
  }

  /// Runs the camera back to the traveller (cut under reduced motion).
  void backToToday({bool building = false}) {
    final at = _exploreAt;
    if (at == null) return;
    // From didUpdateWidget a build is already coming, so no setState there.
    void apply(VoidCallback f) => building ? f() : setState(f);
    _glide.stop();
    if (_reduce) {
      apply(() {
        _exploreAt = null;
        _showBack = false;
      });
      return;
    }
    final stops = (at - _posNow).abs();
    _back.duration = Duration(
        milliseconds: (420 + 90 * math.sqrt(stops)).round().clamp(420, 1200));
    apply(() => _showBack = false);
    _back.forward(from: 0);
  }

  /// A screen reader's scroll: move the camera by [stops] and settle.
  void _scrollBy(double stops) {
    final here = _lookNow();
    _glide.stop();
    _back.stop();
    _back.value = 0;
    _moveTo(here + stops);
    setState(() {});
  }

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
    if (oldWidget.visibleBottom != widget.visibleBottom) {
      oldWidget.visibleBottom?.removeListener(_panelMoved);
      widget.visibleBottom?.addListener(_panelMoved);
    }
    _syncLandmarks();
    _syncWindow(_target);
    if (_exploreAt != null) {
      if (oldWidget.plan?.id != widget.plan?.id) {
        // A different plan: its road starts afresh at its own traveller.
        _glide.stop();
        _back.stop();
        _exploreAt = null;
        _showBack = false;
      } else {
        _exploreAt = clampLook(_exploreAt!, widget.totalDays);
      }
    }
    final target = _target, dusk = _duskTarget;
    if (target == _to && dusk == _dusk1) return;
    // A day was read (or the plan changed) while exploring: bring the camera
    // home so the walk is seen.
    if (_exploreAt != null) {
      final last = widget.totalDays.toDouble();
      if (_exploreAt! > last) _exploreAt = last;
      backToToday(building: true);
    }
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
    widget.visibleBottom?.removeListener(_panelMoved);
    _settle?.cancel();
    _walk.dispose();
    _ambient.dispose();
    _fade.dispose();
    _glide.dispose();
    _back.dispose();
    _nudge.dispose();
    _cache.hills?.dispose();
    super.dispose();
  }

  /// A touch that lands on a gliding camera only stops it: it must not also
  /// open whatever stop slides under the finger.
  bool _swallowTap = false;

  void _pointerDown(PointerDownEvent e) {
    _swallowTap = _glide.isAnimating || _back.isAnimating;
    if (!_swallowTap) return;
    final here = _lookNow();
    _glide.stop();
    _back.stop();
    _back.value = 0;
    _exploreAt = here;
    setState(() => _showBack = (here - _posNow).abs() > 1.2);
  }

  void _onTap(TapUpDetails d) {
    if (_swallowTap) {
      _swallowTap = false;
      return;
    }
    final k = widget.width / RoadScene.designWidth;
    final p = d.localPosition / k;
    // Landmarks stand in front of their stop, so they win the tap.
    for (final h in _cache.hits.reversed) {
      if (h.rect.contains(p)) {
        widget.onLandmarkTap?.call(h.landmark, h.n);
        return;
      }
    }
    final cam = _cameraAt(_lookNow());
    final guess = ((cam.dy - p.dy) / _geo.spacing).round();
    int? best;
    var bestD = double.infinity;
    for (var n = guess - 1; n <= guess + 1; n++) {
      if (n < 1 || n > widget.totalDays) continue;
      final s = _geo.stop(n);
      final dx = (p.dx - (s.x + cam.dx)).abs(),
          dy = (p.dy - (s.y + cam.dy)).abs();
      if (dx > 40 || dy > 30) continue;
      final dist = dx * dx + dy * dy;
      if (dist < bestD) {
        bestD = dist;
        best = n;
      }
    }
    if (best != null) widget.onStopTap?.call(best);
  }

  Offset _cameraAt(double look) {
    final c = _geo.camera(look, focus: _focus);
    return Offset(c.x, c.y);
  }

  Timer? _settle;

  /// The panel moves by repaint only; once it rests, rebuild so the semantics
  /// map (which stops are above the panel) follows it.
  void _panelMoved() {
    _settle?.cancel();
    _settle = Timer(const Duration(milliseconds: 160), () {
      if (mounted) setState(() {});
    });
  }

  double get _k => widget.width / RoadScene.designWidth;
  double get _sceneHeight => widget.height ?? RoadScene.heightFor(widget.width);

  /// Where the reading panel starts, in design px from the scene's top.
  double get _panelTop => (widget.visibleBottom?.value ?? 392 * _k) / _k;

  /// Design y where the camera holds its look: the same share of the road
  /// visible above the panel as in the design (300 of 392).
  double get _focus => _panelTop * (RoadGeometry.focusY / 392);

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final painter = _RoadPainter(
      repaint: Listenable.merge([
        _walk,
        _ambient,
        _nudge,
        _back,
        if (widget.visibleBottom != null) widget.visibleBottom!
      ]),
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
      showTomorrowTag: widget.showTomorrowTag && widget.currentDay != null,
      semantics: _semantics,
      lookOf: _lookNow,
      focusOf: () => _focus,
    );
    return SizedBox(
      width: widget.width,
      height: _sceneHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: Semantics(
              container: true,
              // Screen-reader scrolling, five stops at a time, in the direction of the
              // matching drag: swipe down brings the road ahead into view.
              onScrollUp: () => _scrollBy(-5),
              onScrollDown: () => _scrollBy(5),
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: _pointerDown,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  excludeFromSemantics: true,
                  onTapUp: _onTap,
                  // No plan, no road to explore.
                  onVerticalDragStart: widget.plan == null ? null : _dragStart,
                  onVerticalDragUpdate:
                      widget.plan == null ? null : _dragUpdate,
                  onVerticalDragEnd: widget.plan == null ? null : _dragEnd,
                  child: FadeTransition(
                    opacity: _fade,
                    child: CustomPaint(painter: painter),
                  ),
                ),
              ),
            ),
          ),
          // Rides the reading panel's top edge, at the right where the road
          // (swinging within 82 px of centre) rarely goes.
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: _PanelRider(
              panelTop: widget.visibleBottom,
              fallback: 392 * _k,
              builder: (hidden) => _BackPill(
                  visible: _showBack && !hidden, onTap: backToToday),
              hide: widget.hideBack,
            ),
          ),
        ],
      ),
    );
  }

  /// One node per stop and per landmark in view, placed for the camera as it
  /// rests (rebuilt when a drag or glide ends) so a screen reader sees a
  /// steady map.
  List<CustomPainterSemantics> _semantics(Size size, _RoadPainter p) {
    final k = size.width / RoadScene.designWidth;
    final look = _lookNow();
    final cam = _cameraAt(look);
    final out = <CustomPainterSemantics>[];
    final current = widget.currentDay;
    // Only what is visible above the reading panel.
    final limit = _panelTop - 12;
    final span = _geo.visibleStops(look, top: 0, bottom: limit, focus: _focus);
    final first = math.max(1, span.first),
        last = math.min(widget.totalDays, span.last);
    for (var n = first; n <= last; n++) {
      final s = _geo.stop(n);
      final c = Offset(s.x + cam.dx, s.y + cam.dy);
      if (c.dy < 24 || c.dy > limit) continue;
      final state = current == null || n < current
          ? DailyStrings.stopDone
          : n == current
              ? (widget.showTomorrowTag
                  ? DailyStrings.tomorrow
                  : DailyStrings.stopToday)
              : DailyStrings.stopAhead;
      out.add(CustomPainterSemantics(
        rect: Rect.fromCenter(center: c * k, width: 70 * k, height: 50 * k),
        properties: SemanticsProperties(
          textDirection: TextDirection.ltr,
          label: DailyStrings.stopSemantics(n, state),
          button: true,
          onTap: () => widget.onStopTap?.call(n),
          sortKey: OrdinalSortKey(n.toDouble()),
        ),
      ));
      final lms = _landmarks[n] ?? const <Landmark>[];
      for (var i = 0; i < lms.length; i++) {
        final lm = lms[i];
        final r = _RoadPainter.landmarkRect(n, cam, i);
        out.add(CustomPainterSemantics(
          rect: Rect.fromLTRB(r.left * k, r.top * k, r.right * k, r.bottom * k),
          properties: SemanticsProperties(
            textDirection: TextDirection.ltr,
            label: '${lm.title}, ${lm.ref}',
            button: true,
            onTap: () => widget.onLandmarkTap?.call(lm, n),
            sortKey: OrdinalSortKey(n + .5 + i * .1),
          ),
        ));
      }
    }
    return out;
  }
}

/// Puts [child] bottom-right, resting 12 px above the panel's top edge.
class _PanelRider extends StatelessWidget {
  const _PanelRider(
      {required this.panelTop,
      required this.fallback,
      required this.builder,
      this.hide});

  final ValueListenable<double>? panelTop;
  final double fallback;
  final Widget Function(bool hidden) builder;
  final ValueListenable<bool>? hide;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      Widget at(double top) => Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: (box.maxHeight - top + 12).clamp(0.0, box.maxHeight)),
              child: hide == null
                  ? builder(false)
                  : ValueListenableBuilder<bool>(
                      valueListenable: hide!,
                      builder: (_, h, __) => builder(h)),
            ),
          );
      final l = panelTop;
      if (l == null) return at(fallback);
      return ValueListenableBuilder<double>(
          valueListenable: l, builder: (_, v, __) => at(v));
    });
  }
}

/// "Back to today": appears once the camera is more than a stop away from the
/// traveller. Fades only when motion is allowed.
class _BackPill extends StatelessWidget {
  const _BackPill({required this.visible, required this.onTap});

  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: reduce ? Duration.zero : const Duration(milliseconds: 180),
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: Semantics(
            button: true,
            label: DailyStrings.backToToday,
            excludeSemantics: true,
            onTap: onTap,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Container(
                height: LumSize.touchTarget,
                padding: const EdgeInsets.symmetric(horizontal: LumSpace.lg),
                decoration: BoxDecoration(
                  color: c.scenePanel,
                  borderRadius: BorderRadius.circular(LumRadius.full),
                  border: Border.all(color: c.borderSubtle),
                  boxShadow: [
                    BoxShadow(
                        color: c.sceneShadow,
                        blurRadius: 14,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.my_location_rounded,
                        size: LumSize.iconSm, color: c.textPrimary),
                    const SizedBox(width: LumSpace.sm),
                    Text(DailyStrings.backToToday,
                        style: LumText.footnoteEmphasized
                            .copyWith(color: c.textPrimary)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
  final soft = const MaskFilter.blur(BlurStyle.normal, 3);
  final shadow = Paint()..color = const Color(0x33000000);

  bool? dark;
  double? ch;
  double? dusk;
  Paint? skyPaint, groundPaint, mistPaint;
  Shader? glowShader;
  Color? glowShaderColor;

  Path? road;
  int roadFrom = -999;
  int roadTotal = -1;
  ui.Image? hills, hillsSrc;
  bool facingRight = false;

  ColorFilter filter(Color tint) => filters.putIfAbsent(
      tint.toARGB32(), () => ColorFilter.mode(tint, BlendMode.modulate));
}

const double _s = 30 / 96; // design px per sprite px (96 px per world unit)
const _coin = Offset(153, 124); // coin top-face centre in stop_*.webp
const _foot = Offset(124, 238); // between the feet in a trav cell
const _cellW = 249.0, _cellH = 316.0, _cols = 7;
const _propScale = {
  'prop_tree': .6,
  'prop_cypress': .6,
  'prop_bush': .62,
  'prop_pond': .8,
  'prop_flowers': .65,
  'prop_rock': .6,
};
const _propKinds = [
  'prop_tree',
  'prop_bush',
  'prop_cypress',
  'prop_pond',
  'prop_flowers',
  'prop_rock',
  'prop_tree',
  'prop_bush',
];
const _landmarkScale = .5;

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
    required this.showTomorrowTag,
    required this.semantics,
    required this.lookOf,
    required this.focusOf,
  }) : super(repaint: repaint);

  final LumColors c;
  final bool dark;
  final RoadArt? art;
  final _Cache cache;
  final AnimationController walk, ambient;
  final double from, to, dusk0, dusk1;
  final int total;
  final bool finished, showTomorrowTag;
  final Map<int, List<Landmark>> landmarks;
  final geo = const RoadGeometry();
  final List<CustomPainterSemantics> Function(Size, _RoadPainter) semantics;

  /// The stop position the camera looks at: the traveller's, or the explorer's.
  final double Function() lookOf;

  /// Design y the camera holds [lookOf] at (moves with the reading panel).
  final double Function() focusOf;

  /// Scene height in design px, set at the start of each paint.
  double ch = RoadScene.designHeight;

  @override
  SemanticsBuilderCallback get semanticsBuilder =>
      (size) => semantics(size, this);

  /// Screen offset to add to a world point so that the camera sits at stop
  /// position [look] (see [RoadGeometry.camera]).
  Offset camera(double look, double focus) {
    final c = geo.camera(look, focus: focus);
    return Offset(c.x, c.y);
  }

  Offset _stopAt(int n, Offset cam) {
    final s = geo.stop(n);
    return Offset(s.x + cam.dx, s.y + cam.dy);
  }

  /// Where landmark [n] stands, in design pixels: outboard of its own stop so
  /// it never sits on the road.
  /// Slot 0 stands outboard of its stop; slot 1 across the road from it.
  static Rect landmarkRect(int n, Offset cam, [int slot = 0]) {
    const geo = RoadGeometry();
    final st = geo.stop(n);
    final side = (st.x > 0 ? 1.0 : -1.0) * (slot == 0 ? 1 : -1);
    const w = 672 * _s * _landmarkScale, h = 576 * _s * _landmarkScale;
    // Locked camera x: pull an outboard sprite in so all of it stays on screen.
    final cx = (st.x + cam.dx + side * 78).clamp(w / 2 + 4, 390 - w / 2 - 4),
        bottom = st.y + cam.dy + 18;
    return Rect.fromLTWH(cx - w / 2, bottom - h * .86, w, h);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / RoadScene.designWidth;
    canvas.save();
    canvas.scale(k);
    ch = size.height / k;
    canvas.clipRect(Rect.fromLTWH(0, 0, 390, ch));

    final t = Curves.easeInOutCubic.transform(walk.value);
    final pos = from + (to - from) * t;
    final dusk = dusk0 + (dusk1 - dusk0) * walk.value;
    final moving = walk.status == AnimationStatus.forward && from != to;
    final secs = ambient.value * 96;
    final pulse = .5 + .5 * math.sin(secs * 2 * math.pi / 2.4);
    final look = lookOf();
    final cam = camera(look, focusOf());
    final tint = _tint(dusk);
    final sp = cache.sprite..colorFilter = cache.filter(tint);
    cache.hits.clear();

    _background(canvas, dusk);
    final hills = _hills();
    if (hills != null) {
      const w = 640.0, h = w * 480 / 2496;
      sp.color = const Color(0xD9FFFFFF);
      canvas.drawImageRect(
          hills,
          Rect.fromLTWH(0, 0, hills.width.toDouble(), hills.height.toDouble()),
          Rect.fromLTWH(
              195 - w / 2 - cam.dx * .06, 150 + _drift(cam, 8) - h, w, h),
          sp);
      sp.color = const Color(0xFFFFFFFF);
    }
    _ground(canvas, dusk, cam);
    _road(canvas, look, dusk, cam);
    _worldSprites(canvas, sp, pos, look, cam, pulse, dusk, tint);
    _mist(canvas, dusk);
    _traveller(canvas, sp, pos, cam, moving);
    _clouds(canvas, sp, secs, cam);
    _labels(canvas, pos, cam);
    canvas.restore();
  }

  // ------------------------------------------------------------------ colour
  Color _tint(double dusk) {
    var t = Color.lerp(
        const Color(0xFFFFFFFF), const Color(0xFFC8B8E0), dusk * .55)!;
    if (dark) t = Color.lerp(t, const Color(0xFF8E9AB8), .8)!;
    return t;
  }

  Color _l(Color a, Color b, double dusk) => Color.lerp(a, b, dusk)!;

  /// The hills sprite with its foot faded to transparent, built once. Without
  /// the fade the sprite's flat bottom edge shows as a hard line across the
  /// scene wherever the meadow is darker than the hills (dark mode).
  ui.Image? _hills() {
    final src = art?['hills'];
    if (src == null) return null;
    final cached = cache.hills;
    if (cached != null && identical(cache.hillsSrc, src)) return cached;
    final w = src.width.toDouble(), h = src.height.toDouble();
    final rec = ui.PictureRecorder();
    final cv = Canvas(rec);
    cv.drawImage(src, Offset.zero, Paint());
    cv.drawRect(
        Rect.fromLTWH(0, h * .45, w, h * .55 + 1),
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = ui.Gradient.linear(Offset(0, h * .45), Offset(0, h),
              const [Color(0xFFFFFFFF), Color(0x00FFFFFF)]));
    final img = rec.endRecording().toImageSync(src.width, src.height);
    cache.hills = img;
    cache.hillsSrc = src;
    return img;
  }

  /// A slow parallax drift for the far layers as the camera climbs, bounded by
  /// [max] so hills and clouds never slide out of the sky however far the road
  /// goes (day 300 looks like day 30).
  double _drift(Offset cam, double max) =>
      max * (1 - math.exp(-(cam.dy - 100) / 700));

  void _background(Canvas canvas, double dusk) {
    final top = _l(c.sceneSkyTop, c.sceneDuskSkyTop, dusk);
    final mid = _l(c.sceneSkyMid, c.sceneDuskSkyMid, dusk);
    final hor = _l(c.sceneSkyHorizon, c.sceneDuskSkyHorizon, dusk);
    final settled = dusk == 0 || dusk == 1;
    if (!(settled &&
        cache.dusk == dusk &&
        cache.ch == ch &&
        cache.dark == dark &&
        cache.skyPaint != null)) {
      cache.skyPaint = Paint()
        ..shader = ui.Gradient.linear(
            Offset.zero, const Offset(0, 330), [top, mid, hor], [0, .55, 1]);
      final land = _l(c.sceneMeadowTop, c.sceneDuskLand, dusk);
      final landLow = _l(c.sceneMeadowBottom, c.sceneDuskLand, dusk);
      final clear = land.withValues(alpha: 0);
      cache.groundPaint = Paint()
        ..shader = ui.Gradient.linear(const Offset(0, 120), Offset(0, ch),
            [clear, land, landLow], [0, .2, 1]);
      cache.mistPaint = Paint()
        ..shader = ui.Gradient.linear(
            const Offset(0, 30),
            const Offset(0, 240),
            [
              hor.withValues(alpha: .98),
              hor.withValues(alpha: .7),
              hor.withValues(alpha: .28),
              hor.withValues(alpha: 0),
            ],
            const [0, .4, .75, 1]);
      cache.dusk = settled ? dusk : null;
      cache.dark = dark;
      cache.ch = ch;
    }
    canvas.drawRect(Rect.fromLTWH(0, 0, 390, ch), cache.skyPaint!);
  }

  void _clouds(Canvas canvas, Paint sp, double secs, Offset cam) {
    final cloud = art?['cloud'];
    if (cloud == null) return;
    final src =
        Rect.fromLTWH(0, 0, cloud.width.toDouble(), cloud.height.toDouble());
    // The top layer of the sky: they drift over the far road, thin enough that
    // a stop under one still reads. Night: faint blue wisps with soft edges.
    final saved = sp.colorFilter;
    if (dark) {
      sp
        ..colorFilter = cache.filter(const Color(0xFF6B7BA8))
        ..maskFilter = cache.soft;
    }
    for (var i = 0; i < 3; i++) {
      // 96 s at 12 or 6 px/s is a whole number of 576 px laps, so the loop
      // restarts unseen, and the lap starts and ends off screen (no pop-in).
      final x = ((secs * (i == 0 ? 12 : 6) + i * 200) % 576) - 190;
      final y = 46.0 + i * 34 + _drift(cam, 12);
      final w = (170 - i * 28).toDouble();
      // Smaller, farther clouds are fainter; lower ones, over the road band,
      // fainter still.
      final a = (dark ? .13 : .5) * (1 - i * .18) * (y > 90 ? .6 : 1);
      sp.color = Color.fromRGBO(255, 255, 255, a);
      canvas.drawImageRect(cloud, src, Rect.fromLTWH(x, y, w, w * 0.48), sp);
    }
    sp
      ..maskFilter = null
      ..colorFilter = saved
      ..color = const Color(0xFFFFFFFF);
  }

  int _hash(int n) {
    var h = (n * 0x45d9f3b) & 0xffffffff;
    h = ((h >> 16) ^ h) * 0x45d9f3b & 0xffffffff;
    return (h >> 16) ^ h;
  }

  void _ground(Canvas canvas, double dusk, Offset cam) {
    canvas.drawRect(Rect.fromLTWH(0, 120, 390, ch - 120), cache.groundPaint!);
    final base = _l(c.sceneMeadowTop, c.sceneDuskLand, dusk);
    const row = 96.0;
    final j0 = ((120 - cam.dy) / row).floor(),
        j1 = ((ch + 20 - cam.dy) / row).ceil();
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
          Rect.fromCenter(
              center: Offset(wx + cam.dx * .98 + 0, wy + cam.dy),
              width: r * 2.2,
              height: r * 1.2),
          f);
    }
  }

  void _road(Canvas canvas, double look, double dusk, Offset cam) {
    final w0 = math.max(0, look.floor() - 9);
    if (cache.road == null ||
        cache.roadFrom != w0 ||
        cache.roadTotal != total) {
      final p = Path();
      const steps = 10;
      // 26 stops cover the scene from the camera feet to its horizon, even full screen; the
      // road stops half a stop past the last day of the plan.
      final n = math.max(
          1, math.min(26 * steps, ((total + .5 - w0) * steps).floor()));
      for (var i = 0; i <= n; i++) {
        final q = geo.at(w0 + i / steps);
        i == 0 ? p.moveTo(q.x, q.y) : p.lineTo(q.x, q.y);
      }
      cache.road = p;
      cache.roadFrom = w0;
      cache.roadTotal = total;
    }
    canvas.save();
    canvas.translate(cam.dx, cam.dy);
    final s = cache.stroke;
    s.strokeWidth = 30;
    s.color = _l(c.sceneRoadEdge, c.sceneDuskLand, dusk * .4);
    canvas.drawPath(cache.road!, s);
    s.strokeWidth = 23;
    s.color = _l(c.sceneRoad, dark ? c.sceneDuskLand : const Color(0xFFD9CDE6),
        dusk * .6);
    canvas.drawPath(cache.road!, s);
    canvas.restore();
  }

  // ----------------------------------------------- props, stops, landmarks
  /// Only the stops and props whose y can reach the screen are touched (see
  /// [RoadGeometry.visibleStops]), so a 365-day road costs the same as a 10-day
  /// one, and nothing is allocated per stop.
  void _worldSprites(Canvas canvas, Paint sp, double pos, double look,
      Offset cam, double pulse, double dusk, Color tint) {
    final v =
        geo.visibleStops(look, top: 20, bottom: ch + 40, focus: focusOf());
    for (var n = v.last; n >= v.first; n--) {
      final lms = landmarks[n];
      // Two landmarks take both sides of the stop: no prop to crowd them.
      final y = _stopAt(n, cam).dy;
      // Above the haze nothing shows: skip it, and its hit target with it.
      if (y < 24) continue;
      if (lms == null || lms.length < 2) _props(canvas, sp, n, cam);
      if (n < 1 || n > total) continue;
      if (lms != null) {
        for (var i = 0; i < lms.length; i++) {
          _landmark(canvas, sp, n, lms[i], i, pos, cam, pulse, tint);
        }
      }
      _stop(canvas, sp, n, pos, cam, pulse, dusk);
    }
  }

  void _props(Canvas canvas, Paint sp, int n, Offset cam) {
    final h = _hash(n + 77);
    final side = geo.stop(n).x > 0 ? -1.0 : 1.0;
    final kind = _propKinds[h % _propKinds.length];
    final img = art?[kind];
    if (img == null) return;
    final lmSide = landmarks[n]?.isNotEmpty == true
        ? (geo.stop(n).x > 0 ? 1.0 : -1.0)
        : 0.0;
    final s = _stopAt(n, cam);
    var dx = side * (118 + (h >> 4) % 46).toDouble();
    if (lmSide != 0 && dx.sign == lmSide) dx = -dx;
    final sc = (_propScale[kind] ?? .6) * _s;
    final w = img.width * sc, hh = img.height * sc;
    final cx = dx + cam.dx;
    final bottom = s.dy + 26 + (h >> 9) % 20;
    sp.color = const Color(0xFFFFFFFF);
    canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        Rect.fromLTWH(cx - w / 2, bottom - hh + 6, w, hh),
        sp);
  }

  void _stop(Canvas canvas, Paint sp, int n, double pos, Offset cam,
      double pulse, double dusk) {
    final lock = art?['stop_lock'],
        done = art?['stop_done'],
        cur = art?['stop_cur'];
    final s = _stopAt(n, cam);
    if (s.dy < 20 || s.dy > ch + 80) return;
    final isDone = finished ? true : pos > n + .0001;
    final base = isDone ? done : lock;
    final dst = Rect.fromLTWH(
        s.dx - _coin.dx * _s, s.dy - _coin.dy * _s, 307 * _s, 249 * _s);
    if (base != null) {
      canvas.drawImageRect(
          base,
          Rect.fromLTWH(0, 0, base.width.toDouble(), base.height.toDouble()),
          dst,
          sp);
    }
    final g = finished ? 0.0 : (1 - (pos - n).abs() * 1.6).clamp(0.0, 1.0);
    if (g > 0 && cur != null) {
      sp.color = Color.fromRGBO(255, 255, 255, g);
      canvas.drawImageRect(
          cur,
          Rect.fromLTWH(0, 0, cur.width.toDouble(), cur.height.toDouble()),
          dst,
          sp);
      sp.color = const Color(0xFFFFFFFF);
      final ring = cache.stroke
        ..strokeWidth = 2.4
        ..color = c.sceneGlow.withValues(alpha: g * (.35 + .5 * pulse));
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(s.dx, s.dy + 2),
              width: 78 + 12 * pulse,
              height: 48 + 8 * pulse),
          ring);
    }
    final label = _text(
        'n$n${g > .5 || isDone ? 'c' : 'u'}',
        '$n',
        LumText.roadDisplayStat28.copyWith(
            fontSize: n > 99 ? 14 : 17,
            height: 1,
            // Dark: the coins are dimmed by the night tint, so the numerals
            // go bright with a soft shadow to hold contrast.
            color: (g > .5 || isDone)
                ? c.sceneStopOnCurrent
                : (dark ? const Color(0xFFF4F6FA) : c.sceneStopOnUpcoming),
            shadows: dark && !(g > .5 || isDone)
                ? const [Shadow(color: Color(0xAA0B0E14), blurRadius: 3)]
                : null));
    label.paint(
        canvas, Offset(s.dx - label.width / 2, s.dy - label.height / 2 - 4));
    if (n == total) _flag(canvas, s, dusk);
  }

  /// A small pennant on the plan's last stop, so the end of the road reads as
  /// the end.
  void _flag(Canvas canvas, Offset s, double dusk) {
    final top = Offset(s.dx + 22, s.dy - 62);
    final pole = cache.stroke
      ..strokeWidth = 2.4
      ..color = _l(c.sceneRoadEdge, c.sceneDuskLand, dusk * .4);
    canvas.drawLine(Offset(top.dx, s.dy - 4), top, pole);
    final cloth = cache.fill..color = c.sceneGlow;
    canvas.drawPath(
        Path()
          ..moveTo(top.dx, top.dy)
          ..lineTo(top.dx + 22, top.dy + 8)
          ..lineTo(top.dx, top.dy + 16)
          ..close(),
        cloth);
  }

  /// A signpost for a landmark whose picture is not drawn yet, so the place
  /// can still be found and tapped.
  void _marker(Canvas canvas, Rect rect, double r, double pulse) {
    final base = Offset(rect.center.dx, rect.bottom - rect.height * .14);
    final a = .55 + .45 * r;
    final post = cache.stroke
      ..strokeWidth = 4
      ..color = c.sceneRoadEdge.withValues(alpha: a);
    canvas.drawLine(base, base.translate(0, -34), post);
    final sign = RRect.fromRectAndRadius(
        Rect.fromCenter(center: base.translate(0, -40), width: 34, height: 24),
        const Radius.circular(7));
    final glow = cache.fill
      ..color = c.sceneGlow.withValues(alpha: (.25 + .35 * pulse) * r);
    canvas.drawRRect(sign.inflate(4), glow);
    canvas.drawRRect(
        sign, cache.fill..color = c.scenePanel.withValues(alpha: a));
    canvas.drawRRect(
        sign,
        cache.stroke
          ..strokeWidth = 1.5
          ..color = c.sceneRoadEdge.withValues(alpha: a));
    // A small four-point star: "something happened here".
    final m = sign.center;
    canvas.drawPath(
        Path()
          ..moveTo(m.dx, m.dy - 7)
          ..quadraticBezierTo(m.dx, m.dy, m.dx + 7, m.dy)
          ..quadraticBezierTo(m.dx, m.dy, m.dx, m.dy + 7)
          ..quadraticBezierTo(m.dx, m.dy, m.dx - 7, m.dy)
          ..quadraticBezierTo(m.dx, m.dy, m.dx, m.dy - 7),
        cache.fill..color = c.sceneGlow.withValues(alpha: a));
  }

  void _landmark(Canvas canvas, Paint sp, int n, Landmark lm, int slot,
      double pos, Offset cam, double pulse, Color tint) {
    final artKey = lm.art;
    // No sprite (none drawn, failed, or not decoded yet): a signpost stands in.
    final img = artKey == null ? null : art?['lm_$artKey'];
    // Reveal as the walker closes in on the stop: it rises, warms and glows.
    final r =
        Curves.easeOut.transform(((pos - (n - .55)) / .55).clamp(0.0, 1.0));
    final rect = landmarkRect(n, cam, slot);
    if (rect.bottom < 40 || rect.top > ch + 40) return;
    if (img == null) {
      // Generous tap target: the sign itself is small.
      cache.hits.add(_Hit(
          Rect.fromCenter(
              center: rect.center.translate(0, 8), width: 56, height: 64),
          lm,
          n));
      _marker(canvas, rect, r, pulse);
      return;
    }
    final shifted = rect.shift(Offset(0, (1 - r) * 14));
    cache.hits.add(_Hit(rect, lm, n));
    if (r > .02) {
      final burst = math.sin(math.pi * ((pos - (n - .3)) / .9).clamp(0.0, 1.0));
      final a = (r * (.5 + .25 * pulse) + burst * .3).clamp(0.0, 1.0);
      final col = c.sceneGlow;
      if (cache.glowShader == null || cache.glowShaderColor != col) {
        cache.glowShader = ui.Gradient.radial(
            Offset.zero, 70, [col, col.withValues(alpha: 0)]);
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
    sp.colorFilter =
        cache.filter(Color.lerp(const Color(0xFFB4BCD0), tint, r)!);
    sp.color = Color.fromRGBO(255, 255, 255, .42 + .58 * r);
    final grown = Rect.fromCenter(
        center: shifted.center,
        width: shifted.width * (.9 + .1 * r),
        height: shifted.height * (.9 + .1 * r));
    canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        grown,
        sp);
    sp.color = const Color(0xFFFFFFFF);
    sp.colorFilter = cache.filter(tint);
  }

  void _mist(Canvas canvas, double dusk) {
    canvas.drawRect(const Rect.fromLTWH(0, 0, 390, 240), cache.mistPaint!);
  }

  // -------------------------------------------------------------- traveller
  void _traveller(
      Canvas canvas, Paint sp, double pos, Offset cam, bool moving) {
    final p = geo.at(pos);
    final x = p.x + cam.dx, y = p.y + cam.dy;
    if (y < -80 || y > ch + 80) return; // the camera is exploring elsewhere
    canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y + 4), width: 34, height: 11),
        cache.shadow);
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
    canvas.drawImageRect(
        sheet, src, Rect.fromLTWH(-_foot.dx * _s, -_foot.dy * _s, w, h), sp);
    canvas.restore();
  }

  // ------------------------------------------------------------ text chips
  TextPainter _text(String key, String text, TextStyle style,
      {double maxWidth = double.infinity}) {
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

  /// Where a chip anchored at [anchorBottomCenter] lands (x kept on screen).
  RRect _chipRect(Offset anchorBottomCenter, TextPainter tp) {
    final w = tp.width + 20;
    final cx = anchorBottomCenter.dx.clamp(8 + w / 2, 382 - w / 2).toDouble();
    return RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, anchorBottomCenter.dy - 12),
            width: w,
            height: tp.height + 10),
        const Radius.circular(LumRadius.full));
  }

  Rect _chip(
      Canvas canvas, Offset anchorBottomCenter, TextPainter tp, double alpha) {
    final r = _chipRect(anchorBottomCenter, tp);
    cache.fill.color = c.scenePanel.withValues(alpha: alpha);
    canvas.drawRRect(r, cache.fill);
    final s = cache.stroke
      ..strokeWidth = 1
      ..color = c.borderSubtle.withValues(alpha: alpha);
    canvas.drawRRect(r, s);
    tp.paint(canvas, r.center.translate(-tp.width / 2, -tp.height / 2));
    return r.outerRect;
  }

  void _labels(Canvas canvas, double pos, Offset cam) {
    final settled = walk.value == 0 || walk.value == 1;
    final taken = <Rect>[];
    for (final h in cache.hits) {
      final here = settled && (pos - h.n).abs() < .01;
      if (!here) continue;
      final tp = _text(
          'lm${h.landmark.id}',
          '${h.landmark.short} · ${h.landmark.ref}',
          LumText.caption
              .copyWith(color: c.textPrimary, fontWeight: FontWeight.w600),
          maxWidth: 220);
      taken.add(_chip(
          canvas, Offset(h.rect.center.dx, h.rect.top + 8), tp, 1));
    }
    if (showTomorrowTag && settled) {
      final s = _stopAt(to.round(), cam);
      final tp = _text(
          'tomorrow',
          DailyStrings.tomorrow,
          LumText.caption
              .copyWith(color: c.textPrimary, fontWeight: FontWeight.w600));
      var at = Offset(s.dx, s.dy - 40);
      // Never on top of a landmark chip: climb above every one it meets.
      for (var i = 0; i <= taken.length; i++) {
        final mine = _chipRect(at, tp).outerRect.inflate(2);
        final hit = taken.where(mine.overlaps).toList();
        if (hit.isEmpty) break;
        final top = hit.map((r) => r.top).reduce(math.min);
        at = Offset(at.dx, top - 4 - mine.height / 2 + 14);
      }
      _chip(canvas, at, tp, 1);
    }
  }

  @override
  bool shouldRepaint(_RoadPainter o) => true;
}
