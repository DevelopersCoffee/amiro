import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:thermion_flutter/thermion_flutter.dart' as thermion;

import 'package:avatar_core/avatar_core.dart';

import 'avatar_asset_resolver.dart';
import 'avatar_renderer_interface.dart';

/// Thin seam over the Filament surface so slot-swap bookkeeping is unit
/// testable without a live platform view.
abstract class FilamentSurface {
  Future<void> loadModel(String assetPath);
  Future<void> removeModel(String assetPath);
}

/// Real [FilamentSurface] backed by thermion_flutter's viewer.
///
/// NOTE (Task 6 API reality check): the brief assumed `ThermionViewer`
/// exposed `loadGlb(path)` / `removeAsset(path)`. The installed
/// `thermion_flutter: 0.5.0` (via `thermion_dart: 0.5.0`) instead exposes:
///   - `Future<ThermionAsset> loadGltf(String uri, {...})` (works for both
///     .gltf and .glb — despite the name, it loads .glb buffers fine, see
///     `loadGltfFromBuffer`'s doc comment which explicitly calls out .glb).
///   - `Future destroyAsset(ThermionAsset asset)` — takes the *asset
///     handle* returned by `loadGltf`, not the path. So this surface keeps
///     a path -> ThermionAsset map to translate `removeModel(path)` calls
///     back into the handle Filament actually needs.
class ThermionFilamentSurface implements FilamentSurface {
  final thermion.ThermionViewer _viewer;
  final Map<String, thermion.ThermionAsset> _loadedAssets = {};

  ThermionFilamentSurface(this._viewer);

  @override
  Future<void> loadModel(String assetPath) async {
    _loadedAssets[assetPath] = await _viewer.loadGltf(assetPath);
  }

  @override
  Future<void> removeModel(String assetPath) async {
    final asset = _loadedAssets.remove(assetPath);
    if (asset != null) {
      await _viewer.destroyAsset(asset);
    }
  }
}

class ThermionAvatarRenderer implements AvatarRenderer {
  final FilamentSurface surface;
  AvatarDefinition? _current;

  // Turntable state. Only set by [create]; the unit-test fake surface has no
  // viewer, so rotation is a no-op there.
  thermion.ThermionViewer? _viewer;
  thermion.Camera? _camera;
  double _yaw = 0;
  bool _applying = false;

  ThermionAvatarRenderer({required this.surface});

  static const double _orbitRadius = 1.25;
  static const double _orbitHeight = 1.45;

  // Three-point rig as travel directions relative to the camera's initial
  // (front) view: warm key from front-upper-left, cool fill from the right,
  // white rim from behind. Re-aimed with the camera on every rotation so the
  // avatar stays lit from every angle instead of going black from behind.
  static final _rig = <_LightSpec>[
    _LightSpec(const thermion.LinearColor(1.0, 0.94, 0.86), 90000, -0.5, -0.45, -1),
    _LightSpec(const thermion.LinearColor(0.75, 0.85, 1.0), 40000, 0.7, -0.2, -1),
    _LightSpec(const thermion.LinearColor(1.0, 1.0, 1.0), 55000, 0.1, -0.3, 1),
  ];

  Future<void> _applyRig(thermion.ThermionViewer viewer, double yaw) async {
    await viewer.destroyLights();
    final c = math.cos(yaw), sn = math.sin(yaw);
    for (final l in _rig) {
      // Rotate about Y by the same angle the camera has orbited.
      await viewer.addDirectLight(
        thermion.DirectLight.sun(
          color: l.color,
          intensity: l.intensity,
          castShadows: false,
          direction: thermion.Vector3(
            l.x * c + l.z * sn,
            l.y,
            -l.x * sn + l.z * c,
          ),
        ),
      );
    }
  }

  /// Orbits the camera (and the light rig with it) around the avatar by
  /// [radians]. Unbounded, so it spins a full 360 degrees and beyond.
  Future<void> rotateBy(double radians) async {
    final viewer = _viewer;
    final camera = _camera;
    if (viewer == null || camera == null) return;
    _yaw = (_yaw + radians) % (2 * math.pi);
    if (_applying) return;
    _applying = true;
    try {
      double applied;
      do {
        applied = _yaw;
        await camera.lookAt(
          thermion.Vector3(
            math.sin(applied) * _orbitRadius,
            _orbitHeight,
            math.cos(applied) * _orbitRadius,
          ),
          focus: thermion.Vector3(0, _orbitHeight, 0),
        );
        await _applyRig(viewer, applied);
      } while (applied != _yaw);
    } finally {
      _applying = false;
    }
  }

  /// Builds a renderer backed by a live Filament engine.
  ///
  /// This is the only place the app is allowed to obtain a Thermion-backed
  /// renderer: the global constraint is that nothing outside this package
  /// imports `thermion_flutter`, so engine construction lives here rather
  /// than in `app/lib/main.dart`.
  ///
  /// `ThermionFlutterPlugin.createViewer()` initializes the Filament engine
  /// and returns a live `ThermionViewer`. Like opening a database, it only
  /// needs to be awaited before `runApp` — it needs no `BuildContext` and no
  /// mounted widget tree.
  static Future<ThermionAvatarRenderer> create() async {
    final viewer = await thermion.ThermionFlutterPlugin.createViewer();

    // `createViewer()` sets up a camera and an (empty, unlit) scene, but
    // adds no light and leaves the camera at its identity transform —
    // confirmed against thermion_dart's `ThermionViewerFFI._initialize()`,
    // which creates a camera and scene but calls neither `addDirectLight`
    // nor `camera.lookAt`. Without a light, Filament's PBR materials render
    // black regardless of whether geometry loaded correctly, which is
    // exactly what device testing on a real Pixel 9 showed (engine
    // initialized fine, glTF loaded without error, screen stayed black).
    // Add a basic sun light and back the camera off from the origin so the
    // placeholder meshes (created near-centered at the origin, full extents
    // well under 2 units) are actually lit and in frame.
    // DirectLight.sun()'s default direction (straight down, (0,-1,0)) only
    // lights top-facing surfaces — invisible to a camera looking at the
    // model's front face. Angle it toward the camera's view direction
    // instead, confirmed necessary on-device: the default direction left
    // the (correctly loaded, correctly framed) mesh silhouette solid black.
    // Framed for a real-world-scale standing humanoid (feet ~y=0, head
    // ~y=1.8, per the Quaternius base character's glTF bounding box) —
    // confirmed on-device that the placeholder-box framing above (looking
    // at the origin from distance 3) put the camera inside a body this
    // size, showing only the thighs. Center vertically on the torso and
    // pull back far enough to fit the whole figure in frame.
    final camera = await viewer.getActiveCamera();
    // Head-and-shoulders framing (a full-body view left the face a few
    // pixels wide with most of the screen empty).
    await camera.lookAt(
      thermion.Vector3(0, _orbitHeight, _orbitRadius),
      focus: thermion.Vector3(0, _orbitHeight, 0),
    );

    final renderer =
        ThermionAvatarRenderer(surface: ThermionFilamentSurface(viewer));
    renderer._viewer = viewer;
    renderer._camera = camera;
    await renderer._applyRig(viewer, 0);
    return renderer;
  }

  @override
  AvatarDefinition? get current => _current;

  @override
  Future<void> load(AvatarDefinition definition) async {
    for (final slot in AvatarDefinition.slots) {
      final assetId = _slotValue(definition, slot);
      if (assetId != null) {
        await surface.loadModel(resolveAssetPath(slot, assetId));
      }
    }
    _current = definition;
  }

  @override
  Future<void> updateSlot(String slot, String? assetId) async {
    final loaded = _current;
    if (loaded == null) {
      throw StateError('updateSlot called before load()');
    }

    final previousAssetId = _slotValue(loaded, slot);
    if (previousAssetId != null) {
      await surface.removeModel(resolveAssetPath(slot, previousAssetId));
    }
    if (assetId != null) {
      await surface.loadModel(resolveAssetPath(slot, assetId));
    }

    _current = loaded.copyWithSlot(slot, assetId);
  }

  @override
  Widget buildView() {
    // `ThermionWidget` (unlike the brief's assumed const, no-arg
    // constructor) requires a live `ThermionViewer` to render into — see
    // API reality check note on `ThermionFilamentSurface` above. That
    // viewer only exists on the real surface, not the test fake, so this
    // is the one place that reaches past the `FilamentSurface` seam.
    final surface = this.surface;
    if (surface is ThermionFilamentSurface) {
      // Horizontal drag orbits the camera: ~one full turn per 2 screen
      // widths of dragging feels natural without needing a second swipe.
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (details) =>
            rotateBy(-details.delta.dx * 0.012),
        child: thermion.ThermionWidget(viewer: surface._viewer),
      );
    }
    throw StateError(
      'buildView() requires a ThermionFilamentSurface backed by a live '
      'ThermionViewer',
    );
  }

  @override
  Future<void> dispose() async {
    _current = null;
  }

  String? _slotValue(AvatarDefinition def, String slot) {
    final json = def.toJson();
    return json[slot] as String?;
  }
}

class _LightSpec {
  final thermion.LinearColor color;
  final double intensity;
  final double x, y, z;
  const _LightSpec(this.color, this.intensity, this.x, this.y, this.z);
}
