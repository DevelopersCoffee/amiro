import 'dart:math' as math;

import 'package:thermion_flutter/thermion_flutter.dart' as thermion;
import 'package:vector_math/vector_math_64.dart';

/// Whether [assetPath] is a skinned humanoid mesh that ships in bind (T) pose
/// with no embedded idle animation (body + skinned clothing slots).
bool shouldApplySkinnedHumanoidProceduralMotion(String assetPath) {
  if (!assetPath.endsWith('.glb')) return false;
  if (assetPath.endsWith('body_placeholder.glb')) return false;
  if (assetPath.contains('/avatars/')) return true;
  if (!assetPath.contains('/cosmetics/')) return false;
  final base = assetPath.split('/').last;
  return base.startsWith('top_') ||
      base.startsWith('bottom_') ||
      base.startsWith('shoes_');
}

/// Whether [assetPath] points at a skinned humanoid body that ships in bind
/// (T) pose with no embedded idle animation.
@Deprecated('Use shouldApplySkinnedHumanoidProceduralMotion')
bool shouldApplyRelaxedArmPose(String assetPath) {
  return shouldApplySkinnedHumanoidProceduralMotion(assetPath);
}

/// Bone names on the Quaternius Superhero / Mixamo-compatible skeleton shipped
/// as [body_superhero_male.glb].
const relaxedArmPoseBones = ['upperarm_l', 'upperarm_r'];

/// Subtle idle motion targets on the same Quaternius skeleton (verified in GLB).
const livingStatueIdleBones = [
  'spine_01',
  'spine_02',
  'spine_03',
  'neck_01',
  'pelvis',
];

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

/// Procedural "living statue" loop: soft breath through the spine chain and a
/// barely perceptible pelvis/neck sway. Amplitudes stay in the Apple product-shot
/// range (almost still).
thermion.BoneAnimationData buildLivingStatueIdleAnimation({
  int numFrames = 120,
  double frameLengthInMs = 1000.0 / 60.0,
  double loopDurationSeconds = 5.5,
}) {
  assert(numFrames >= 2);
  final frames = <thermion.SkeletonTransform>[];
  for (var frameIndex = 0; frameIndex < numFrames; frameIndex++) {
    final t = frameIndex / numFrames;
    final phase = 2 * math.pi * t;
    final breath = math.sin(phase);
    final sway = math.sin(phase + math.pi / 3);

    final spine01 = Quaternion.axisAngle(
      Vector3(1, 0, 0),
      0.004 * breath,
    );
    final spine02 = Quaternion.axisAngle(
      Vector3(1, 0, 0),
      0.007 * breath,
    );
    final spine03 = Quaternion.axisAngle(
      Vector3(1, 0, 0),
      0.010 * breath,
    );
    final neck = Quaternion.axisAngle(
      Vector3(1, 0, 0),
      -0.003 * breath,
    );
    final pelvisRot = Quaternion.axisAngle(Vector3(0, 1, 0), 0.005 * sway) *
        Quaternion.axisAngle(Vector3(1, 0, 0), 0.003 * sway);

    final chestLift = Vector3(0, 0.0012 * breath, 0);

    frames.add([
      (rotation: spine01, translation: Vector3.zero()),
      (rotation: spine02, translation: chestLift),
      (rotation: spine03, translation: Vector3.zero()),
      (rotation: neck, translation: Vector3.zero()),
      (rotation: pelvisRot, translation: Vector3.zero()),
    ]);
  }

  // Stretch frame timing so one loop spans [loopDurationSeconds].
  final msPerFrame = (loopDurationSeconds * 1000) / numFrames;

  return thermion.BoneAnimationData(
    livingStatueIdleBones,
    frames,
    frameLengthInMs: msPerFrame,
    space: thermion.Space.Bone,
  );
}

/// Applies relaxed arms plus looping idle motion to a loaded skinned asset.
///
/// The shipped GLBs contain **zero** glTF animation clips; Filament renders the
/// bind pose until bones are driven manually.
Future<void> applySkinnedHumanoidProceduralMotion(
  thermion.ThermionAsset asset,
) async {
  await asset.addAnimationComponent();
  await asset.addBoneAnimation(
    buildRelaxedArmPoseAnimation(),
    loop: true,
  );
  await asset.addBoneAnimation(
    buildLivingStatueIdleAnimation(),
    loop: true,
  );
}

/// Applies a looping relaxed arm pose to a loaded skinned body asset.
@Deprecated('Use applySkinnedHumanoidProceduralMotion')
Future<void> applyRelaxedArmPose(thermion.ThermionAsset asset) async {
  await applySkinnedHumanoidProceduralMotion(asset);
}
