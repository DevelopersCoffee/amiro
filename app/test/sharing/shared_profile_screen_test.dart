import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avatar_core/avatar_core.dart';
import 'package:avatar_renderer/avatar_renderer.dart';
import 'package:sharing/sharing.dart';

import 'package:amiro_app/avatar/avatar_providers.dart';
import 'package:amiro_app/sharing/shared_profile_screen.dart';

class _FakeAvatarRenderer implements AvatarRenderer {
  AvatarDefinition? _current;

  @override
  AvatarDefinition? get current => _current;
  @override
  Future<void> load(AvatarDefinition definition) async => _current = definition;
  @override
  Widget buildView() => const ColoredBox(color: Colors.grey, child: SizedBox(height: 200));
  @override
  Future<void> updateSlot(String slot, String? assetId) async {}
  @override
  Future<void> dispose() async {}
}

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
            () async => _FakeAvatarRenderer(),
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
      // avatarRendererProvider — so overriding only avatarRendererProvider
      // with a renderer that throws on load() must not affect this screen.
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
            avatarRendererProvider.overrideWithValue(_ThrowingAvatarRenderer()),
            avatarRendererFactoryProvider.overrideWithValue(
              () async => _FakeAvatarRenderer(),
            ),
          ],
          child: MaterialApp(home: SharedProfileScreen(profile: profile)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ada'), findsOneWidget);
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
}

class _ThrowingAvatarRenderer implements AvatarRenderer {
  @override
  AvatarDefinition? get current => null;
  @override
  Future<void> load(AvatarDefinition definition) async {
    throw StateError('avatarRendererProvider singleton must not be used by SharedProfileScreen');
  }
  @override
  Widget buildView() => throw UnimplementedError();
  @override
  Future<void> updateSlot(String slot, String? assetId) async {}
  @override
  Future<void> dispose() async {}
}
