import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:thermion_flutter/thermion_flutter.dart' as thermion;

import 'package:avatar_core/avatar_core.dart';

import 'package:vector_math/vector_math_64.dart' show Matrix4, Vector3;

import 'avatar_asset_resolver.dart';
import 'avatar_body_pose.dart';
import 'avatar_renderer_interface.dart';
import 'avatar_viewer_presentation.dart';

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
    final asset = await _viewer.loadGltf(assetPath);
    _loadedAssets[assetPath] = asset;

    // Quaternius ships hair/brow/beard textures as un-tinted grey, meant to
    // be colored in-engine. Multiply in a dark chestnut via the glTF
    // baseColorFactor (linear RGB). Best-effort: a tint failure must never
    // stop the model itself from showing.
    final tint = _hairTint(assetPath);
    if (assetPath.contains('/avatars/')) {
      // The body mesh carries its own (grey) eyebrows as a child mesh.
      try {
        for (final name in await asset.getChildEntityNames()) {
          if (name != null && name.toLowerCase().contains('eyebrow')) {
            final entity = await asset.getChildEntity(name);
            final material = await asset.getMaterialInstanceAt(entity: entity);
            await material.setParameterFloat4(
                'baseColorFactor', 0.35, 0.17, 0.08, 1.0);
          }
        }
      } catch (_) {}
    }
    if (tint != null) {
      try {
        final instances = await asset.getMaterialInstancesAsMap();
        for (final list in instances.values) {
          for (final material in list) {
            await material.setParameterFloat4(
                'baseColorFactor', tint[0], tint[1], tint[2], 1.0);
          }
        }
      } catch (_) {}
    }

    // Body meshes are rigged but ship with no idle clip — Filament shows the
    // bind (T) pose until bones are driven. Best-effort: a pose failure must
    // never prevent the model from appearing.
    if (shouldApplySkinnedHumanoidProceduralMotion(assetPath)) {
      try {
        await applySkinnedHumanoidProceduralMotion(asset);
      } catch (_) {}
    }
  }

  static List<double>? _hairTint(String assetPath) {
    final name = assetPath.split('/').last;
    if (name.startsWith('hair_') ||
        name.startsWith('eyebrows_') ||
        name.startsWith('beard_')) {
      return const [0.35, 0.17, 0.08];
    }
    return null;
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

  static const double _orbitRadius = avatarOrbitRadius;
  static const double _orbitFocusHeight = avatarOrbitFocusHeight;
  static const double _orbitCameraHeight = avatarOrbitCameraHeight;

  // Boutique three-point rig: warm key (with floor shadow), cool fill, rim.
  // Re-aimed with the camera on every rotation so full-body stays lit while
  // orbiting.
  static final _rig = <_LightSpec>[
    _LightSpec(
      const thermion.LinearColor(1.0, 0.90, 0.78),
      105000,
      -0.55,
      -0.38,
      -1,
      castShadows: true,
    ),
    _LightSpec(
      const thermion.LinearColor(0.62, 0.76, 1.0),
      48000,
      0.78,
      -0.18,
      -1,
    ),
    _LightSpec(
      const thermion.LinearColor(0.92, 0.88, 1.0),
      82000,
      0.05,
      -0.08,
      1,
    ),
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
          castShadows: l.castShadows,
          direction: thermion.Vector3(
            l.x * c + l.z * sn,
            l.y,
            -l.x * sn + l.z * c,
          ),
        ),
      );
    }

    // Soft top-back wash — studio rim without gaming neon.
    final spotX = 0.15 * c + 0.55 * sn;
    final spotZ = -0.15 * sn + 0.55 * c;
    await viewer.addDirectLight(
      thermion.DirectLight.spot(
        color: const thermion.LinearColor(0.98, 0.86, 0.62),
        intensity: 95000,
        castShadows: false,
        position: thermion.Vector3(spotX, 2.35, spotZ),
        direction: thermion.Vector3(-spotX * 0.35, -1.05, -spotZ * 0.35),
        spotLightConeInner: math.pi / 10,
        spotLightConeOuter: math.pi / 5,
        falloffRadius: 8,
      ),
    );
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
            _orbitCameraHeight,
            math.cos(applied) * _orbitRadius,
          ),
          focus: thermion.Vector3(0, _orbitFocusHeight, 0),
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
    try {
      await viewer.setBackgroundImage(
        avatarStageBackdropAsset,
        fillHeight: true,
      );
    } catch (_) {
      try {
        await viewer.setBackgroundColor(
          avatarStageBackgroundR,
          avatarStageBackgroundG,
          avatarStageBackgroundB,
          1.0,
        );
      } catch (_) {}
    }
    try {
      await _installStagePlinth(viewer);
    } catch (_) {}

    // Full-body hero framing (feet ~y=0, head ~y=1.8 on Quaternius skeleton).
    final camera = await viewer.getActiveCamera();
    await camera.lookAt(
      thermion.Vector3(0, _orbitCameraHeight, _orbitRadius),
      focus: thermion.Vector3(0, _orbitFocusHeight, 0),
    );

    final renderer =
        ThermionAvatarRenderer(surface: ThermionFilamentSurface(viewer));
    renderer._viewer = viewer;
    renderer._camera = camera;
    await renderer._applyRig(viewer, 0);
    return renderer;
  }

  /// Extended floor, circular plinth, and brass ring so the avatar reads as a
  /// fashion hero on a boutique stage — not floating in a flat void.
  static Future<void> _installStagePlinth(thermion.ThermionViewer viewer) async {
    final floorMaterial = await _pbrStageMaterial(
      viewer,
      avatarStageFloorColorR,
      avatarStageFloorColorG,
      avatarStageFloorColorB,
      roughness: 0.98,
    );
    final floor = await viewer.createGeometry(
      thermion.GeometryUtils.plane(
        width: avatarStageFloorDiameter,
        height: avatarStageFloorDiameter,
      ),
      materialInstances: [floorMaterial],
    );
    await floor.setTransform(Matrix4.identity());

    final lipMaterial = await _pbrStageMaterial(
      viewer,
      avatarStagePlinthColorR,
      avatarStagePlinthColorG,
      avatarStagePlinthColorB,
      roughness: 0.94,
    );
    final lip = await viewer.createGeometry(
      thermion.GeometryUtils.cylinder(
        radius: avatarStagePlinthRadius,
        length: avatarStagePlinthHeight,
      ),
      materialInstances: [lipMaterial],
    );
    await lip.setTransform(
      Matrix4.translation(Vector3(0, avatarStagePlinthCenterY, 0)),
    );

    final diskMaterial = await _pbrStageMaterial(
      viewer,
      avatarStageDiskColorR,
      avatarStageDiskColorG,
      avatarStageDiskColorB,
      roughness: 0.88,
      metallic: 0.04,
    );
    final disk = await viewer.createGeometry(
      thermion.GeometryUtils.plane(
        width: avatarStageDiskDiameter,
        height: avatarStageDiskDiameter,
      ),
      materialInstances: [diskMaterial],
    );
    await disk.setTransform(
      Matrix4.translation(Vector3(0, avatarStagePlinthHeight, 0)),
    );

    final ringMaterial = await _pbrStageMaterial(
      viewer,
      avatarStageRingColorR,
      avatarStageRingColorG,
      avatarStageRingColorB,
      roughness: 0.35,
      metallic: 0.55,
      emissiveScale: 0.22,
    );
    final ring = await viewer.createGeometry(
      thermion.GeometryUtils.cylinder(
        radius: avatarStageRingRadius,
        length: avatarStageRingHeight,
      ),
      materialInstances: [ringMaterial],
    );
    await ring.setTransform(
      Matrix4.translation(Vector3(0, avatarStageRingCenterY, 0)),
    );
  }

  static Future<dynamic> _pbrStageMaterial(
    thermion.ThermionViewer viewer,
    double r,
    double g,
    double b, {
    double roughness = 0.9,
    double metallic = 0.0,
    double emissiveScale = 0.0,
  }) async {
    final material = await viewer.app.createUbershaderMaterialInstance(
      unlit: false,
      hasVertexColors: false,
    );
    await material.setParameterFloat4('baseColorFactor', r, g, b, 1.0);
    await material.setParameterFloat('roughnessFactor', roughness);
    await material.setParameterFloat('metallicFactor', metallic);
    if (emissiveScale > 0) {
      await material.setParameterFloat4(
        'emissiveFactor',
        r * emissiveScale,
        g * emissiveScale,
        b * emissiveScale,
        1.0,
      );
    }
    return material;
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
  final bool castShadows;
  const _LightSpec(
    this.color,
    this.intensity,
    this.x,
    this.y,
    this.z, {
    this.castShadows = false,
  });
}
