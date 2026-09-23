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

  ThermionAvatarRenderer({required this.surface});

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
    await viewer.addDirectLight(
      thermion.DirectLight.sun(direction: thermion.Vector3(-0.4, -0.6, -1)),
    );
    final camera = await viewer.getActiveCamera();
    await camera.lookAt(
      thermion.Vector3(0, 0, 3),
      focus: thermion.Vector3(0, 0, 0),
    );

    return ThermionAvatarRenderer(surface: ThermionFilamentSurface(viewer));
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
      return thermion.ThermionWidget(viewer: surface._viewer);
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
