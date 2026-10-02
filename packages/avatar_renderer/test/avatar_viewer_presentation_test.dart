import 'package:avatar_renderer/src/avatar_viewer_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('avatar hero framing', () {
    test('centers on standing figure and pulls back for full body', () {
      expect(avatarOrbitFocusHeight, greaterThan(0.75));
      expect(avatarOrbitFocusHeight, lessThan(1.1));
      expect(avatarOrbitRadius, greaterThan(2.0));
      expect(avatarOrbitCameraHeight, greaterThanOrEqualTo(avatarOrbitFocusHeight));
    });

    test('stage disk and plinth lip meet at ground level', () {
      expect(avatarStagePlinthCenterY, avatarStagePlinthHeight / 2);
      expect(avatarStageDiskDiameter, greaterThan(1.2));
    });
  });
}
