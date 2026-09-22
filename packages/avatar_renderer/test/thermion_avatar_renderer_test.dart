import 'package:avatar_core/avatar_core.dart';
import 'package:avatar_renderer/avatar_renderer.dart';
import 'package:avatar_renderer/src/thermion_avatar_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fakes the Filament engine calls so this test doesn't require a live
/// platform view. Real engine wiring is exercised in the app's
/// integration test (Task 10).
class _FakeFilamentSurface implements FilamentSurface {
  final List<String> loadedPaths = [];

  @override
  Future<void> loadModel(String assetPath) async {
    loadedPaths.add(assetPath);
  }

  @override
  Future<void> removeModel(String assetPath) async {
    loadedPaths.remove(assetPath);
  }
}

void main() {
  late _FakeFilamentSurface surface;
  late ThermionAvatarRenderer renderer;

  setUp(() {
    surface = _FakeFilamentSurface();
    renderer = ThermionAvatarRenderer(surface: surface);
  });

  test('current is null before load', () {
    expect(renderer.current, isNull);
  });

  test('load sets current and loads each populated slot as a model', () async {
    const definition = AvatarDefinition(id: 'avatar-1', body: 'body_placeholder', top: 'top_placeholder');

    await renderer.load(definition);

    expect(renderer.current, definition);
    expect(surface.loadedPaths, containsAll([
      'packages/avatar_renderer/assets/avatars/body_placeholder.glb',
      'packages/avatar_renderer/assets/cosmetics/top_placeholder.glb',
    ]));
  });

  test('updateSlot swaps the model for that slot only', () async {
    const definition = AvatarDefinition(id: 'avatar-1', body: 'body_placeholder', top: 'top_placeholder');
    await renderer.load(definition);

    await renderer.updateSlot('glasses', 'glasses_placeholder');

    expect(renderer.current!.glasses, 'glasses_placeholder');
    expect(surface.loadedPaths, contains(
      'packages/avatar_renderer/assets/cosmetics/glasses_placeholder.glb',
    ));
  });

  test('updateSlot with null removes the previously loaded model for that slot', () async {
    const definition = AvatarDefinition(id: 'avatar-1', body: 'body_placeholder', top: 'top_placeholder');
    await renderer.load(definition);

    await renderer.updateSlot('top', null);

    expect(renderer.current!.top, isNull);
    expect(surface.loadedPaths, isNot(contains(
      'packages/avatar_renderer/assets/cosmetics/top_placeholder.glb',
    )));
  });

  test('updateSlot before load throws StateError', () {
    expect(() => renderer.updateSlot('top', 'top_placeholder'), throwsStateError);
  });
}
