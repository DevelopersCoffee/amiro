import 'dart:math' as math;

import 'package:avatar_renderer/src/avatar_body_pose.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thermion_flutter/thermion_flutter.dart' as thermion;

void main() {
  group('shouldApplyRelaxedArmPose', () {
    test('applies to skinned superhero body', () {
      expect(
        shouldApplyRelaxedArmPose(
          'packages/avatar_renderer/assets/avatars/body_superhero_male.glb',
        ),
        isTrue,
      );
    });

    test('skips procedural placeholder body', () {
      expect(
        shouldApplyRelaxedArmPose(
          'packages/avatar_renderer/assets/avatars/body_placeholder.glb',
        ),
        isFalse,
      );
    });

    test('skips cosmetics', () {
      expect(
        shouldApplyRelaxedArmPose(
          'packages/avatar_renderer/assets/cosmetics/top_peasant_shirt.glb',
        ),
        isFalse,
      );
    });
  });

  group('buildRelaxedArmPoseAnimation', () {
    test('targets upper arm bones with a held bone-space twist', () {
      final animation = buildRelaxedArmPoseAnimation(
        armDownRadians: math.pi / 2,
      );

      expect(animation.bones, relaxedArmPoseBones);
      expect(animation.space, thermion.Space.Bone);
      expect(animation.numFrames, 1);

      final frame = animation.frameData.single;
      expect(frame.length, 2);

      final left = frame[0].rotation;
      final right = frame[1].rotation;
      expect(left, isNot(equals(right)));

      // Opposite-signed Z twists for left vs right arm.
      expect(left.z, greaterThan(0));
      expect(right.z, lessThan(0));
    });
  });
}
