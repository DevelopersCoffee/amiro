import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avatar_core/avatar_core.dart';
import 'package:avatar_renderer/avatar_renderer.dart';
import 'package:sharing/sharing.dart';
import 'package:store/store.dart';

import 'package:amiro_app/avatar/avatar_providers.dart';
import 'package:amiro_app/sharing/shared_profile_screen.dart';

import '../avatar/fake_avatar_renderer.dart';

void main() {
  testWidgets('renders the shared profile\'s name, username, bio and avatar', (tester) async {
    final profile = SharedProfile(
      id: 'id-1',
      displayName: 'Ada',
      username: 'ada',
      bio: 'Engineer',
      avatarDefinitionJson: jsonEncode(
        const AvatarDefinition(id: 'shared', body: 'body_superhero_male').toJson(),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          avatarRendererFactoryProvider.overrideWithValue(
            () async => FakeAvatarRenderer(),
          ),
        ],
        child: MaterialApp(home: SharedProfileScreen(profile: profile)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('@ada'), findsOneWidget);
    expect(find.text('Engineer'), findsOneWidget);
  });

  Widget card(SharedProfile profile) => ProviderScope(
        child: MaterialApp(home: SharedProfileScreen(profile: profile)),
      );

  testWidgets('shows the rarest collected item and series progress', (tester) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final profile = SharedProfile(
      id: 'id-1',
      displayName: 'Ada',
      username: 'ada',
      ownedCosmeticIds: const ['classic_frame', 'riviera_optics'],
    );

    await tester.pumpWidget(card(profile));
    await tester.pumpAndSettle();

    final rarest = rarestCosmetic(cosmeticCatalog, {'classic_frame', 'riviera_optics'})!;
    final series = rarest.series!;
    final progress = collectionProgress(cosmeticCatalog, {'riviera_optics'})
        .firstWhere((p) => p.series.number == series.number);

    expect(find.text(rarest.name), findsOneWidget);
    expect(find.text(rarest.rarity.label), findsOneWidget);
    expect(find.text(series.label), findsOneWidget);
    expect(find.text('${progress.owned} / ${progress.total}'), findsOneWidget);
  });

  testWidgets('omits the collection section when the card shares nothing', (tester) async {
    await tester.pumpWidget(
      card(SharedProfile(id: 'id-1', displayName: 'Ada', username: 'ada')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Collection'), findsNothing);
  });

  testWidgets('ignores cosmetic ids this app version does not know', (tester) async {
    await tester.pumpWidget(
      card(SharedProfile(
        id: 'id-1',
        displayName: 'Ada',
        username: 'ada',
        ownedCosmeticIds: const ['from_the_future'],
      )),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Rarest'), findsNothing);
  });

  testWidgets('renders without a bio section when bio is null', (tester) async {
    final profile = SharedProfile(id: 'id-1', displayName: 'Ada', username: 'ada');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: SharedProfileScreen(profile: profile)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ada'), findsOneWidget);
  });

  testWidgets(
    'never touches the shared avatarRendererProvider singleton for a scanned profile',
    (tester) async {
      // Regression test for the bug this fix round addresses: loading a
      // stranger's avatar definition into the app's own singleton
      // renderer would bleed their meshes into the live scene and corrupt
      // AvatarScreen's re-entry guard. SharedProfileScreen must get its
      // avatar exclusively from avatarRendererFactoryProvider, never from
      // avatarRendererProvider. A prior version of this test only checked
      // that the screen still rendered — which a broken implementation
      // could also satisfy — so this asserts directly on the singleton's
      // observable state: its `load()` call count stays zero and its
      // `current` stays untouched by whatever the screen loaded.
      final singleton = _SpyAvatarRenderer();
      final scannedProfile = SharedProfile(
        id: 'id-1',
        displayName: 'Ada',
        username: 'ada',
        avatarDefinitionJson: jsonEncode(
          const AvatarDefinition(id: 'shared', body: 'body_superhero_male').toJson(),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            avatarRendererProvider.overrideWithValue(singleton),
            avatarRendererFactoryProvider.overrideWithValue(
              () async => FakeAvatarRenderer(),
            ),
          ],
          child: MaterialApp(home: SharedProfileScreen(profile: scannedProfile)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ada'), findsOneWidget);
      expect(singleton.loadCallCount, 0);
      expect(singleton.current, isNull);
    },
  );

  testWidgets(
    'does not crash when the avatar renderer factory throws',
    (tester) async {
      final profile = SharedProfile(
        id: 'id-1',
        displayName: 'Ada',
        username: 'ada',
        avatarDefinitionJson: jsonEncode(
          const AvatarDefinition(id: 'shared', body: 'body_superhero_male').toJson(),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            avatarRendererFactoryProvider.overrideWithValue(() async {
              throw StateError('boom');
            }),
          ],
          child: MaterialApp(home: SharedProfileScreen(profile: profile)),
        ),
      );
      // Not pumpAndSettle: the failed load leaves the avatar slot showing
      // a CircularProgressIndicator, which animates forever and would
      // time out pumpAndSettle. A couple of plain pumps is enough for the
      // failed _init() future to resolve.
      await tester.pump();
      await tester.pump();

      // Screen still renders the rest of the profile despite the failure.
      expect(find.text('Ada'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'disposes the renderer if the factory succeeds but load() fails',
    (tester) async {
      // Regression test for fix round 2's leak: previously `renderer` was
      // declared inside the `try` block, so a `load()` failure (fed by
      // untrusted, scanned data — a real path) skipped disposal of the
      // already-constructed renderer entirely.
      final leakyRenderer = _FailingLoadAvatarRenderer();
      final profile = SharedProfile(
        id: 'id-1',
        displayName: 'Ada',
        username: 'ada',
        avatarDefinitionJson: jsonEncode(
          const AvatarDefinition(id: 'shared', body: 'body_superhero_male').toJson(),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            avatarRendererFactoryProvider.overrideWithValue(() async => leakyRenderer),
          ],
          child: MaterialApp(home: SharedProfileScreen(profile: profile)),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Ada'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(leakyRenderer.disposeCallCount, 1);
    },
  );
}

/// Records calls instead of throwing, so tests can assert the
/// app-lifetime singleton was never touched by [SharedProfileScreen].
class _SpyAvatarRenderer implements AvatarRenderer {
  AvatarDefinition? _current;
  int loadCallCount = 0;

  @override
  AvatarDefinition? get current => _current;
  @override
  Future<void> load(AvatarDefinition definition) async {
    loadCallCount++;
    _current = definition;
  }
  @override
  Widget buildView() => const SizedBox.shrink();
  @override
  Future<void> updateSlot(String slot, String? assetId) async {}
  @override
  Future<void> dispose() async {}
}

/// A renderer that constructs successfully but fails on `load()` — the
/// leak scenario fix round 2 addresses. Tracks `dispose()` calls so the
/// test can assert the already-constructed instance was cleaned up.
class _FailingLoadAvatarRenderer implements AvatarRenderer {
  int disposeCallCount = 0;

  @override
  AvatarDefinition? get current => null;
  @override
  Future<void> load(AvatarDefinition definition) async {
    throw StateError('malformed scanned avatar definition');
  }
  @override
  Widget buildView() => throw UnimplementedError();
  @override
  Future<void> updateSlot(String slot, String? assetId) async {}
  @override
  Future<void> dispose() async {
    disposeCallCount++;
  }
}
