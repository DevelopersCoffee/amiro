import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_core/identity_core.dart';

import 'package:amiro_app/avatar/avatar_loader.dart';
import 'package:amiro_app/avatar/avatar_providers.dart';
import 'package:amiro_app/identity/identity_providers.dart';

import '../identity/in_memory_identity_repository.dart';
import 'fake_avatar_renderer.dart';

void main() {
  setUp(resetAvatarLoadChainForTest);

  test('ensureAvatarLoaded forceReload swaps in the female body', () async {
    final repo = InMemoryIdentityRepository();
    final renderer = FakeAvatarRenderer();
    final container = ProviderContainer(
      overrides: [
        identityRepositoryProvider.overrideWithValue(repo),
        avatarRendererProvider.overrideWithValue(renderer),
      ],
    );
    addTearDown(container.dispose);

    await container.read(currentIdentityProvider.notifier).save(
      Identity(
        id: 'id-1',
        displayName: 'Alex',
        username: 'alex',
        avatarGender: 'male',
      ),
    );

    final first = await ensureAvatarLoaded(container);
    expect(first.bodyAssetPending, isFalse);
    expect(renderer.current, isNotNull);

    await container.read(currentIdentityProvider.notifier).save(
      Identity(
        id: 'id-1',
        displayName: 'Alex',
        username: 'alex',
        avatarGender: 'female',
      ),
    );

    final second = await ensureAvatarLoaded(container, forceReload: true);
    expect(second.bodyAssetPending, isFalse);
    expect(renderer.current?.body, 'body_superhero_female');
    expect(renderer.calls, contains('unload'));
  });

  test('ensureAvatarLoaded reloads male body after a female load', () async {
    final container = ProviderContainer(
      overrides: [
        identityRepositoryProvider.overrideWithValue(InMemoryIdentityRepository()),
        avatarRendererProvider.overrideWithValue(FakeAvatarRenderer()),
      ],
    );
    addTearDown(container.dispose);
    final renderer = container.read(avatarRendererProvider) as FakeAvatarRenderer;

    await container.read(currentIdentityProvider.notifier).save(
      Identity(
        id: 'id-1',
        displayName: 'Alex',
        username: 'alex',
        avatarGender: 'male',
      ),
    );
    await ensureAvatarLoaded(container);
    expect(renderer.current, isNotNull);

    await container.read(currentIdentityProvider.notifier).save(
      Identity(
        id: 'id-1',
        displayName: 'Alex',
        username: 'alex',
        avatarGender: 'female',
      ),
    );
    final female = await ensureAvatarLoaded(container, forceReload: true);
    expect(female.bodyAssetPending, isFalse);
    expect(renderer.current?.body, 'body_superhero_female');
    expect(container.read(avatarSceneDefinitionProvider)?.body, 'body_superhero_female');

    await container.read(currentIdentityProvider.notifier).save(
      Identity(
        id: 'id-1',
        displayName: 'Alex',
        username: 'alex',
        avatarGender: 'male',
      ),
    );
    final restored = await ensureAvatarLoaded(container, forceReload: true);
    expect(restored.bodyAssetPending, isFalse);
    expect(renderer.current?.body, 'body_superhero_male');
    expect(container.read(avatarSceneDefinitionProvider)?.body, 'body_superhero_male');
  });

  test('resolveDefinitionForLoad aligns body slot after gender change', () {
    const json =
        '{"id":"saved","body":"body_superhero_male","hair":"hair_simple_parted","facialHair":"beard_full"}';
    final identity = Identity(
      id: 'id-1',
      displayName: 'Alex',
      username: 'alex',
      avatarGender: 'male',
      avatarDefinitionJson: json,
    );
    final def = resolveDefinitionForLoad(identity, afterGenderChange: true);
    expect(def.body, 'body_superhero_male');
    expect(def.facialHair, 'beard_full');

    final female = resolveDefinitionForLoad(
      identity.copyWith(avatarGender: 'female'),
      afterGenderChange: true,
    );
    expect(female.body, 'body_superhero_female');
    expect(female.hair, 'hair_buns');
    expect(female.facialHair, isNull);

    final paid = resolveDefinitionForLoad(
      identity.copyWith(
        avatarGender: 'female',
        avatarDefinitionJson:
            '{"id":"saved","body":"body_superhero_male","hair":"hair_long"}',
      ),
      afterGenderChange: true,
    );
    expect(paid.hair, 'hair_long');
    expect(paid.body, 'body_superhero_female');
  });

  test('forceReload from a loaded female body still reloads male', () async {
    final container = ProviderContainer(
      overrides: [
        identityRepositoryProvider.overrideWithValue(InMemoryIdentityRepository()),
        avatarRendererProvider.overrideWithValue(FakeAvatarRenderer()),
      ],
    );
    addTearDown(container.dispose);
    final renderer = container.read(avatarRendererProvider) as FakeAvatarRenderer;

    await container.read(currentIdentityProvider.notifier).save(
      Identity(
        id: 'id-1',
        displayName: 'Alex',
        username: 'alex',
        avatarGender: 'male',
      ),
    );
    await ensureAvatarLoaded(container);
    await container.read(currentIdentityProvider.notifier).save(
      Identity(
        id: 'id-1',
        displayName: 'Alex',
        username: 'alex',
        avatarGender: 'female',
      ),
    );
    final female = await ensureAvatarLoaded(container, forceReload: true);
    expect(female.bodyAssetPending, isFalse);
    expect(renderer.current?.body, 'body_superhero_female');

    await container.read(currentIdentityProvider.notifier).save(
      Identity(
        id: 'id-1',
        displayName: 'Alex',
        username: 'alex',
        avatarGender: 'male',
      ),
    );
    await ensureAvatarLoaded(container, forceReload: true);
    expect(renderer.current, isNotNull);
    expect(renderer.calls.where((c) => c == 'unload').length, greaterThanOrEqualTo(1));
    expect(renderer.calls.where((c) => c.startsWith('load:')).length, greaterThanOrEqualTo(2));
  });

  test('ensureAvatarLoaded forceReload unloads stale current before load', () async {
    final container = ProviderContainer(
      overrides: [
        identityRepositoryProvider.overrideWithValue(InMemoryIdentityRepository()),
        avatarRendererProvider.overrideWithValue(FakeAvatarRenderer()),
      ],
    );
    addTearDown(container.dispose);
    final renderer = container.read(avatarRendererProvider) as FakeAvatarRenderer;

    await container.read(currentIdentityProvider.notifier).save(
      Identity(
        id: 'id-1',
        displayName: 'Alex',
        username: 'alex',
        avatarGender: 'male',
      ),
    );
    await ensureAvatarLoaded(container);
    expect(renderer.current, isNotNull);

    // Simulate stale current without meshes — forceReload must unload first.
    await ensureAvatarLoaded(container, forceReload: true);
    expect(renderer.calls.where((c) => c == 'unload').length, greaterThanOrEqualTo(1));
    expect(renderer.calls.where((c) => c.startsWith('load:')).length, greaterThanOrEqualTo(2));
  });

  test('the first avatar load creates an identity for that look', () async {
    final repo = InMemoryIdentityRepository();
    final container = ProviderContainer(
      overrides: [
        identityRepositoryProvider.overrideWithValue(repo),
        avatarRendererProvider.overrideWithValue(FakeAvatarRenderer()),
      ],
    );
    addTearDown(container.dispose);

    await ensureAvatarLoaded(container);

    final saved = await repo.getCurrent();
    expect(saved, isNotNull);
    expect(saved!.avatarDefinitionJson, isNotNull);
    expect(saved.avatarDefinitionJson, contains('body_superhero_male'));
  });
}
