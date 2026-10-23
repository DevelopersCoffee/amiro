import 'dart:math' as math;

import 'package:avatar_renderer/src/avatar_body_pose.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldApplySkinnedHumanoidProceduralMotion', () {
    test('applies to skinned superhero body', () {
      expect(
        shouldApplySkinnedHumanoidProceduralMotion(
          'packages/avatar_renderer/assets/avatars/body_superhero_male.glb',
        ),
        isTrue,
      );
    });

    test('applies to skinned clothing that shares the body skeleton', () {
      expect(
        shouldApplySkinnedHumanoidProceduralMotion(
          'packages/avatar_renderer/assets/cosmetics/top_peasant_shirt.glb',
        ),
        isTrue,
      );
      expect(
        shouldApplySkinnedHumanoidProceduralMotion(
          'packages/avatar_renderer/assets/cosmetics/shoes_peasant_boots.glb',
        ),
        isTrue,
      );
    });

    test('skips procedural placeholder body', () {
      expect(
        shouldApplySkinnedHumanoidProceduralMotion(
          'packages/avatar_renderer/assets/avatars/body_placeholder.glb',
        ),
        isFalse,
      );
    });

    test('skips rigid-parented cosmetics', () {
      expect(
        shouldApplySkinnedHumanoidProceduralMotion(
          'packages/avatar_renderer/assets/cosmetics/glasses_placeholder.glb',
        ),
        isFalse,
      );
    });
  });

  group('buildSkinnedHumanoidPresentationAnimation', () {
    test('includes arm hold on every idle frame', () {
      final animation = buildSkinnedHumanoidPresentationAnimation(
        numFrames: 60,
      );

      expect(animation.bones, skinnedHumanoidPresentationBones);
      expect(animation.numFrames, 60);

      final hold = confidentFashionArmPoseFrame();
      for (final frame in animation.frameData) {
        expect(frame[0].rotation, equals(hold.left.rotation));
        expect(frame[1].rotation, equals(hold.right.rotation));
      }
    });

    test('confident arms keep device-verified Z twist sign', () {
      final hold = confidentFashionArmPoseFrame(armDownRadians: math.pi / 2);
      expect(hold.left.rotation.z, lessThan(0));
      expect(hold.right.rotation.z, greaterThan(0));
      expect(
        hold.left.rotation,
        isNot(equals(hold.right.rotation)),
      );
    });

    test('loop wrap has only a tiny discontinuity at frame 0', () {
      final animation = buildSkinnedHumanoidPresentationAnimation(
        numFrames: 120,
      );
      final first = animation.frameData.first;
      final last = animation.frameData.last;

      for (var i = relaxedArmPoseBones.length;
          i < skinnedHumanoidPresentationBones.length;
          i++) {
        expect(first[i].rotation.x, closeTo(last[i].rotation.x, 0.02));
      }
    });
  });
}
