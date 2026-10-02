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

/// All bones driven by [buildSkinnedHumanoidPresentationAnimation] (arms + idle).
const skinnedHumanoidPresentationBones = [
  ...relaxedArmPoseBones,
  ...livingStatueIdleBones,
];

Quaternion _boneLocalRotation(Vector3 axis, double radians) {
  return Quaternion.axisAngle(axis, radians);
}

/// vector_math 2.2+ — use operator `*` (mutable [Quaternion.multiply] removed).
Quaternion _combineBoneRotations(Quaternion a, Quaternion b) => a * b;

/// Builds a single-frame skeletal hold that drops the upper arms from the glTF
/// bind (T) pose. Rotations are in [Space.Bone] — deltas applied on top of
/// each bone's rest local transform inside thermion's [addBoneAnimation].
///
/// Sign convention verified against `body_superhero_male.glb` on device (PR #35):
/// **left −π/2**, **right +π/2** about bone-local +Z — the opposite pairing
/// swings arms toward world +Y (overhead).
thermion.BoneAnimationData buildRelaxedArmPoseAnimation({
  double armDownRadians = math.pi / 2,
}) {
  final frame = confidentFashionArmPoseFrame(
    armDownRadians: armDownRadians,
  );
  return thermion.BoneAnimationData(
    relaxedArmPoseBones,
    [
      [frame.left, frame.right],
    ],
    frameLengthInMs: 60000,
    space: thermion.Space.Bone,
  );
}

/// Boutique idle arm hold: **only** the device-verified upper-arm Z twist.
///
/// Extra X/Y deltas on `upperarm_*` stacked a second limb on front camera
/// (four-arm glitch on Pixel, PR #38 verify). Presence comes from torso idle;
/// arms stay a single clean hang at left −π/2 / right +π/2.
({thermion.Transform left, thermion.Transform right}) confidentFashionArmPoseFrame({
  double armDownRadians = math.pi / 2,
}) {
  final left = _boneLocalRotation(Vector3(0, 0, 1), -armDownRadians);
  final right = _boneLocalRotation(Vector3(0, 0, 1), armDownRadians);

  return (
    left: (rotation: left, translation: Vector3.zero()),
    right: (rotation: right, translation: Vector3.zero()),
  );
}

/// Arm-space deltas reused in every frame of the presentation loop.
@Deprecated('Use confidentFashionArmPoseFrame')
({thermion.Transform left, thermion.Transform right}) relaxedArmPoseFrame({
  double armDownRadians = math.pi / 2,
}) {
  return confidentFashionArmPoseFrame(armDownRadians: armDownRadians);
}

/// Static contrapposto / open-chest offsets layered under breath and sway.
thermion.SkeletonTransform confidentFashionTorsoFrame({
  required double breath,
  required double sway,
}) {
  final spine01 = _boneLocalRotation(Vector3(1, 0, 0), 0.012 + 0.004 * breath);
  final spine02 = _boneLocalRotation(Vector3(1, 0, 0), -0.045 + 0.007 * breath);
  final spine03 = _boneLocalRotation(Vector3(1, 0, 0), -0.035 + 0.010 * breath);
  final neck = _boneLocalRotation(Vector3(1, 0, 0), 0.028 - 0.003 * breath);

  final pelvisRot = _combineBoneRotations(
    _boneLocalRotation(Vector3(0, 1, 0), 0.055 + 0.005 * sway),
    _combineBoneRotations(
      _boneLocalRotation(Vector3(1, 0, 0), -0.018 + 0.003 * sway),
      _boneLocalRotation(Vector3(0, 0, 1), 0.012),
    ),
  );

  final chestLift = Vector3(0, 0.002 + 0.0012 * breath, 0);

  return [
    (rotation: spine01, translation: Vector3.zero()),
    (rotation: spine02, translation: chestLift),
    (rotation: spine03, translation: Vector3.zero()),
    (rotation: neck, translation: Vector3.zero()),
    (rotation: pelvisRot, translation: Vector3.zero()),
  ];
}

/// One looping clip: confident arm hold on **every** frame plus breath/sway.
///
/// A single [addBoneAnimation] avoids Thermion cross-fading separate clips on
/// the same instance and keeps skinned clothing instances in lockstep with the
/// body when each mesh gets the same data.
thermion.BoneAnimationData buildSkinnedHumanoidPresentationAnimation({
  int numFrames = 120,
  double loopDurationSeconds = 5.5,
  double armDownRadians = math.pi / 2,
}) {
  assert(numFrames >= 2);
  final arms = confidentFashionArmPoseFrame(armDownRadians: armDownRadians);
  final frames = <thermion.SkeletonTransform>[];

  for (var frameIndex = 0; frameIndex < numFrames; frameIndex++) {
    final t = frameIndex / numFrames;
    final phase = 2 * math.pi * t;
    final breath = math.sin(phase);
    final sway = math.sin(phase + math.pi / 3);

    final torso = confidentFashionTorsoFrame(breath: breath, sway: sway);

    frames.add([
      arms.left,
      arms.right,
      ...torso,
    ]);
  }

  final msPerFrame = (loopDurationSeconds * 1000) / numFrames;

  return thermion.BoneAnimationData(
    skinnedHumanoidPresentationBones,
    frames,
    frameLengthInMs: msPerFrame,
    space: thermion.Space.Bone,
  );
}

/// Procedural "living statue" loop (idle bones only). Prefer
/// [buildSkinnedHumanoidPresentationAnimation] at runtime.
thermion.BoneAnimationData buildLivingStatueIdleAnimation({
  int numFrames = 120,
  double loopDurationSeconds = 5.5,
}) {
  final full = buildSkinnedHumanoidPresentationAnimation(
    numFrames: numFrames,
    loopDurationSeconds: loopDurationSeconds,
  );
  return thermion.BoneAnimationData(
    livingStatueIdleBones,
    full.frameData
        .map(
          (frame) => frame.sublist(relaxedArmPoseBones.length),
        )
        .toList(),
    frameLengthInMs: full.frameLengthInMs,
    space: thermion.Space.Bone,
  );
}

/// Applies relaxed arms plus looping idle motion to a loaded skinned asset.
Future<void> applySkinnedHumanoidProceduralMotion(
  thermion.ThermionAsset asset,
) async {
  final boneNames = await asset.getBoneNames();
  if (!boneNames.contains('upperarm_l') ||
      !boneNames.contains('upperarm_r')) {
    return;
  }

  await asset.addAnimationComponent();
  await asset.addBoneAnimation(
    buildSkinnedHumanoidPresentationAnimation(),
    loop: true,
  );
}

@Deprecated('Use applySkinnedHumanoidProceduralMotion')
Future<void> applyRelaxedArmPose(thermion.ThermionAsset asset) async {
  await applySkinnedHumanoidProceduralMotion(asset);
}
