import 'dart:math' as math;

import 'package:thermion_flutter/thermion_flutter.dart' as thermion;
import 'package:vector_math/vector_math_64.dart';

/// Whether [assetPath] points at a skinned humanoid body that ships in bind
/// (T) pose with no embedded idle animation.
bool shouldApplyRelaxedArmPose(String assetPath) {
  if (!assetPath.contains('/avatars/')) return false;
  // Procedural placeholder box — no skeleton to pose.
  if (assetPath.endsWith('body_placeholder.glb')) return false;
  return true;
}

/// Bone names on the Quaternius Superhero / Mixamo-compatible skeleton shipped
/// as [body_superhero_male.glb].
const relaxedArmPoseBones = ['upperarm_l', 'upperarm_r'];

/// Builds a single-frame skeletal hold that drops the upper arms from the glTF
/// bind (T) pose. Rotations are in [Space.Bone] — deltas applied on top of
/// each bone's rest local transform inside thermion's [addBoneAnimation].
thermion.BoneAnimationData buildRelaxedArmPoseAnimation({
  double armDownRadians = math.pi / 2,
}) {
  // Mixamo-style upper arms point sideways in bind pose; a +Z / −Z twist in
  // bone space brings them down to a natural standing rest.
  final left = Quaternion.axisAngle(Vector3(0, 0, 1), armDownRadians);
  final right = Quaternion.axisAngle(Vector3(0, 0, 1), -armDownRadians);
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

/// Applies a looping relaxed arm pose to a loaded skinned body asset.
///
/// The shipped body GLB contains **zero** glTF animation clips (verified in
/// repo); Filament therefore renders the bind pose (T-pose) until we drive
/// bones manually.
Future<void> applyRelaxedArmPose(thermion.ThermionAsset asset) async {
  await asset.addAnimationComponent();
  await asset.addBoneAnimation(
    buildRelaxedArmPoseAnimation(),
    loop: true,
  );
}
