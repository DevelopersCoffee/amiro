import 'dart:math' as math;

import 'package:thermion_flutter/thermion_flutter.dart' as thermion;
import 'package:vector_math/vector_math_64.dart';

/// Procedural placeholder — no skeleton.
bool assetPathSkipsRelaxedArmPose(String assetPath) {
  return assetPath.endsWith('body_placeholder.glb');
}

/// Bone names on the Quaternius / Mixamo-compatible skeleton (body + skinned
/// cosmetics such as [top_peasant_shirt.glb] duplicate this rig).
const relaxedArmPoseBones = ['upperarm_l', 'upperarm_r'];

/// Whether [asset] is a skinned mesh that still needs arms dropped from bind
/// (T) pose. Each loaded glTF is a separate Filament instance, so the body and
/// skinned clothing must be posed independently.
Future<bool> skinnedAssetNeedsRelaxedArmPose(thermion.ThermionAsset asset) async {
  try {
    final names = await asset.getBoneNames();
    return names.contains('upperarm_l') && names.contains('upperarm_r');
  } catch (_) {
    return false;
  }
}

/// Builds a single-frame skeletal hold that drops the upper arms from bind pose.
///
/// Thermion [thermion.Space.Bone] applies `restLocal * delta` (see
/// `FFIAsset.addBoneAnimation`) — it **replaces** the driven bone's local
/// transform each frame; it does not stack a second skeleton on top of bind
/// pose. The "four arms" device bug was wrong rotation (arms up) plus skinned
/// cosmetics left in T-pose because only `/avatars/` paths were posed.
///
/// Axis choice (verified against `body_superhero_male.glb` joint hierarchy):
/// at rest, each upper arm's local +Y points horizontally (T-pose). A **−π/2**
/// twist about local +Z on the left arm (and **+π/2** on the right) swings
/// that direction to world −Y (arms at the sides).
thermion.BoneAnimationData buildRelaxedArmPoseAnimation({
  double armDownRadians = math.pi / 2,
}) {
  final left = Quaternion.axisAngle(Vector3(0, 0, 1), -armDownRadians);
  final right = Quaternion.axisAngle(Vector3(0, 0, 1), armDownRadians);
  final frame = [
    (rotation: left, translation: Vector3.zero()),
    (rotation: right, translation: Vector3.zero()),
  ];
  return thermion.BoneAnimationData(
    relaxedArmPoseBones,
    [frame],
    frameLengthInMs: 60000,
    space: thermion.Space.Bone,
  );
}

/// Applies a looping relaxed arm pose to one loaded glTF instance.
Future<void> applyRelaxedArmPose(thermion.ThermionAsset asset) async {
  await asset.addAnimationComponent();
  await asset.addBoneAnimation(
    buildRelaxedArmPoseAnimation(),
    loop: true,
    fadeInInSecs: 0,
    maxDelta: 1.0,
  );
}

/// Poses [asset] when it carries the shared humanoid skeleton.
Future<void> applyRelaxedArmPoseIfNeeded(
  thermion.ThermionAsset asset,
  String assetPath,
) async {
  if (assetPathSkipsRelaxedArmPose(assetPath)) return;
  if (!await skinnedAssetNeedsRelaxedArmPose(asset)) return;
  await applyRelaxedArmPose(asset);
}
