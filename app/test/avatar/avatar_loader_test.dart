import 'package:avatar_core/avatar_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_core/identity_core.dart';

import 'package:amiro_app/avatar/avatar_loader.dart';
import 'package:amiro_app/avatar/avatar_providers.dart';
import 'package:amiro_app/identity/identity_providers.dart';

import '../identity/in_memory_identity_repository.dart';
import 'fake_avatar_renderer.dart';

void main() {
  test('ensureAvatarLoaded unloads male avatar when identity switches to female', () async {
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

    final first = await ensureAvatarLoaded(container.read);
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

    final second = await ensureAvatarLoaded(container.read);
    expect(second.bodyAssetPending, isTrue);
    expect(renderer.current, isNull);
    expect(renderer.calls, contains('unload'));
  });

  test('ensureAvatarLoaded reloads after female gate then male restore', () async {
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
    await ensureAvatarLoaded(container.read);
    expect(renderer.current, isNotNull);

    await container.read(currentIdentityProvider.notifier).save(
      Identity(
        id: 'id-1',
        displayName: 'Alex',
        username: 'alex',
        avatarGender: 'female',
      ),
    );
    await ensureAvatarLoaded(container.read);
    expect(renderer.current, isNull);
    expect(container.read(avatarSceneDefinitionProvider), isNull);

    await container.read(currentIdentityProvider.notifier).save(
      Identity(
        id: 'id-1',
        displayName: 'Alex',
        username: 'alex',
        avatarGender: 'male',
      ),
    );
    final restored = await ensureAvatarLoaded(container.read);
    expect(restored.bodyAssetPending, isFalse);
    expect(renderer.current, isNotNull);
    expect(container.read(avatarSceneDefinitionProvider), isNotNull);
    expect(renderer.calls, contains('resumePresentation'));
  });
}
