import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_scene/scene.dart' hide Animation;
import 'package:vector_math/vector_math.dart' as vm;

import '../../domain/landmark_3d.dart';

/// A landmark glb standing on the podium, turned by [turns] (the showcase's
/// spin controller, so whoosh, idle turn and drag inertia drive it).
///
/// It loads its one model as soon as it is built, but only mounts the 3D view
/// (and so only ticks and draws) while [active]. It tells the parent through
/// [onShown] when the first 3D frame is up, and through [onFailed] if 3D is
/// unavailable here or the model would not load; the parent keeps its static
/// sprite in that case. Nothing is held once it is disposed.
class LandmarkModel3d extends StatefulWidget {
  const LandmarkModel3d({
    super.key,
    required this.art,
    required this.turns,
    required this.active,
    required this.onShown,
    required this.onFailed,
  });

  final String art;
  final Animation<double> turns;
  final bool active;
  final VoidCallback onShown, onFailed;

  @override
  State<LandmarkModel3d> createState() => _LandmarkModel3dState();
}

class _LandmarkModel3dState extends State<LandmarkModel3d> {
  static const _dir = 'assets/images/road/models';
  static Map<String, LandmarkFraming>? _framings;
  static bool _logged = false;

  Scene? _scene;
  Node? _pivot;
  PerspectiveCamera? _camera;
  LandmarkFraming? _framing;
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  void _fail(Object e) {
    if (!_logged) {
      _logged = true;
      debugPrint('landmark3d unavailable, showing the sprite: $e');
    }
    if (mounted) widget.onFailed();
  }

  Future<void> _load() async {
    try {
      // Static resources and shaders are initialised once, then reused.
      await Scene.initializeStaticResources();
      _framings ??=
          parseFramings(await rootBundle.loadString('$_dir/manifest.json'));
      final framing = _framings![widget.art];
      if (framing == null) throw StateError('no framing for ${widget.art}');
      final model = await Node.fromGlbAsset('$_dir/${widget.art}.glb');
      if (!mounted) return;
      final pivot = Node()..add(model);
      // Soft key over a dim ambient: the glb's colour is already shaded, so
      // the lights only add gentle form, not a second full shading.
      final scene = Scene()
        ..environmentIntensity = .55
        ..directionalLight = DirectionalLight(
          direction: vm.Vector3(.35, -1, .55),
          intensity: .9,
        )
        ..add(pivot);
      final (x, y, z) = framing.eye;
      setState(() {
        _scene = scene;
        _pivot = pivot;
        _framing = framing;
        _camera = PerspectiveCamera(
          fovRadiansY: LandmarkFraming.fovYDeg * math.pi / 180,
          position: vm.Vector3(x, y, z),
          target: vm.Vector3(0, framing.targetY, 0),
        );
      });
    } catch (e) {
      _fail(e);
    }
  }

  void _tick(Duration _, double __) {
    final yaw = (widget.turns.value + _framing!.yawStartTurns) * 2 * math.pi;
    _pivot!.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), yaw);
    if (!_shown) {
      _shown = true;
      widget.onShown();
    }
  }

  @override
  void dispose() {
    final scene = _scene;
    _scene = null;
    // The SceneView child is unmounted just after this; free the GPU scene
    // once that is done.
    if (scene != null) scheduleMicrotask(scene.dispose);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scene;
    if (scene == null || !widget.active) return const SizedBox.shrink();
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SceneView(scene, camera: _camera, onTick: _tick),
      ),
    );
  }
}
