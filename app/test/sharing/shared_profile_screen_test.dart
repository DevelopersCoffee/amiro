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
        overrides: [avatarRendererProvider.overrideWithValue(_FakeAvatarRenderer())],
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
        overrides: [avatarRendererProvider.overrideWithValue(_FakeAvatarRenderer())],
        child: MaterialApp(home: SharedProfileScreen(profile: profile)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ada'), findsOneWidget);
  });
}
