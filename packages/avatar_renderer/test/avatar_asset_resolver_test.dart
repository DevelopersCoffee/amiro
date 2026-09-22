import 'package:avatar_renderer/avatar_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolveAssetPath maps slot + asset id to a packaged asset path', () {
    expect(
      resolveAssetPath('body', 'body_placeholder'),
      'packages/avatar_renderer/assets/avatars/body_placeholder.glb',
    );
    expect(
      resolveAssetPath('top', 'top_placeholder'),
      'packages/avatar_renderer/assets/cosmetics/top_placeholder.glb',
    );
    expect(
      resolveAssetPath('glasses', 'glasses_placeholder'),
      'packages/avatar_renderer/assets/cosmetics/glasses_placeholder.glb',
    );
  });

  test('resolveAssetPath throws for an unknown slot', () {
    expect(() => resolveAssetPath('cape', 'cape_01'), throwsArgumentError);
  });
}
