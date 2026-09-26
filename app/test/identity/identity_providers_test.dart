import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:identity_core/identity_core.dart';

import 'package:amiro_app/identity/identity_providers.dart';

import 'in_memory_identity_repository.dart';

void main() {
  test('currentIdentityProvider starts null then loads from repository', () async {
    final repo = InMemoryIdentityRepository();
    await repo.save(Identity(id: 'id-1', displayName: 'Uday', username: 'uday'));

    final container = ProviderContainer(overrides: [
      identityRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    final identity = await container.read(currentIdentityProvider.future);

    expect(identity!.displayName, 'Uday');
  });

  test('save persists through the repository and updates state', () async {
    final repo = InMemoryIdentityRepository();
    final container = ProviderContainer(overrides: [
      identityRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    await container.read(currentIdentityProvider.future);
    await container.read(currentIdentityProvider.notifier).save(
          Identity(id: 'id-1', displayName: 'Uday', username: 'uday'),
        );

    final stored = await repo.getCurrent();
    expect(stored!.displayName, 'Uday');
    expect(container.read(currentIdentityProvider).value!.displayName, 'Uday');
  });
}
