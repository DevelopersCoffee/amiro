import 'dart:math' as math;

import 'package:avatar_renderer/src/avatar_body_pose.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thermion_flutter/thermion_flutter.dart' as thermion;

void main() {
  group('assetPathSkipsRelaxedArmPose', () {
    test('only skips procedural placeholder body', () {
      expect(
        assetPathSkipsRelaxedArmPose(
          'packages/avatar_renderer/assets/avatars/body_placeholder.glb',
        ),
        isTrue,
      );
      expect(
        assetPathSkipsRelaxedArmPose(
          'packages/avatar_renderer/assets/avatars/body_superhero_male.glb',
        ),
        isFalse,
      );
      expect(
        assetPathSkipsRelaxedArmPose(
          'packages/avatar_renderer/assets/cosmetics/top_peasant_shirt.glb',
        ),
        isFalse,
      );
    });
  });

  group('buildRelaxedArmPoseAnimation', () {
    test('targets upper arm bones with opposing Z twists (arms down, not up)', () {
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

      // Left: −π/2 about local Z; right: +π/2 (see avatar_body_pose.dart).
      expect(left.z, lessThan(0));
      expect(right.z, greaterThan(0));
    });
  });
}
