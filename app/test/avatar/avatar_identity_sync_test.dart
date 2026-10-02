import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_core/identity_core.dart';

import 'package:amiro_app/avatar/avatar_identity_sync.dart';
import 'package:amiro_app/avatar/avatar_providers.dart';
import 'package:amiro_app/identity/identity_providers.dart';

import '../identity/in_memory_identity_repository.dart';
import 'fake_avatar_renderer.dart';

void main() {
  testWidgets('first identity emission does not forceReload avatar', (tester) async {
    final renderer = FakeAvatarRenderer();
    final repo = InMemoryIdentityRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          identityRepositoryProvider.overrideWithValue(repo),
          avatarRendererProvider.overrideWithValue(renderer),
        ],
        child: const MaterialApp(
          home: AvatarIdentitySyncListener(
            child: SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await repo.save(
      Identity(
        id: 'id-1',
        displayName: 'Alex',
        username: 'alex',
        avatarGender: 'male',
      ),
    );
    await tester.pumpAndSettle();

    expect(renderer.calls.where((c) => c == 'unload'), isEmpty);
    expect(renderer.calls.where((c) => c.startsWith('load:')), isEmpty);
  });
}
