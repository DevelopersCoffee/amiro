import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avatar_core/avatar_core.dart';
import 'package:avatar_renderer/avatar_renderer.dart';
import 'package:identity_core/identity_core.dart';

import 'package:amiro_app/avatar/avatar_providers.dart';
import 'package:amiro_app/avatar/avatar_screen.dart';
import 'package:amiro_app/identity/identity_providers.dart';

class _InMemoryIdentityRepository implements IdentityRepository {
  Identity? stored;

  _InMemoryIdentityRepository([this.stored]);

  @override
  Future<Identity?> getCurrent() async => stored;

  @override
  Future<void> save(Identity identity) async => stored = identity;

  @override
  Future<void> clear() async => stored = null;
}

Identity _identity({String? avatarDefinitionJson}) => Identity(
      id: 'id-1',
      displayName: 'Uday',
      username: 'uday',
      avatarDefinitionJson: avatarDefinitionJson,
    );

Widget _screen(AvatarRenderer renderer, IdentityRepository repository) {
  return ProviderScope(
    overrides: [
      avatarRendererProvider.overrideWithValue(renderer),
      identityRepositoryProvider.overrideWithValue(repository),
    ],
    child: const MaterialApp(home: AvatarScreen()),
  );
}

class _FakeAvatarRenderer implements AvatarRenderer {
  AvatarDefinition? _current;
  final List<String> calls = [];

  @override
  AvatarDefinition? get current => _current;

  @override
  Future<void> load(AvatarDefinition definition) async {
    calls.add('load:${definition.id}');
    _current = definition;
  }

  @override
  Widget buildView() => const ColoredBox(color: Colors.grey, child: SizedBox(height: 200));

  @override
  Future<void> updateSlot(String slot, String? assetId) async {
    calls.add('updateSlot:$slot:$assetId');
    _current = _current!.copyWithSlot(slot, assetId);
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  testWidgets('avatar screen loads the definition on start and renders a view', (tester) async {
    final renderer = _FakeAvatarRenderer();

    await tester.pumpWidget(_screen(renderer, _InMemoryIdentityRepository()));
    await tester.pumpAndSettle();

    expect(renderer.calls, contains('load:default'));
    // MaterialApp's default route transition also builds a transient,
    // transparent ColoredBox as part of its FadeTransition/SlideTransition
    // chain, so match on the fake renderer's own grey ColoredBox rather than
    // any ColoredBox in the tree.
    expect(
      find.byWidgetPredicate((widget) => widget is ColoredBox && widget.color == Colors.grey),
      findsOneWidget,
    );
  });

  testWidgets('tapping the glasses toggle swaps that slot', (tester) async {
    final renderer = _FakeAvatarRenderer();

    await tester.pumpWidget(_screen(renderer, _InMemoryIdentityRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('toggleGlassesButton')));
    await tester.pumpAndSettle();

    expect(renderer.calls, contains('updateSlot:glasses:glasses_realistic'));
    expect(renderer.current!.glasses, 'glasses_realistic');
  });

  testWidgets('tapping again removes the glasses', (tester) async {
    final renderer = _FakeAvatarRenderer();

    await tester.pumpWidget(_screen(renderer, _InMemoryIdentityRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('toggleGlassesButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('toggleGlassesButton')));
    await tester.pumpAndSettle();

    expect(renderer.current!.glasses, isNull);
  });

  testWidgets('the rendered definition is persisted onto the current identity',
      (tester) async {
    final renderer = _FakeAvatarRenderer();
    final repository = _InMemoryIdentityRepository(_identity());

    await tester.pumpWidget(_screen(renderer, repository));
    await tester.pumpAndSettle();

    // Persisted after the initial load...
    final afterLoad =
        jsonDecode(repository.stored!.avatarDefinitionJson!) as Map<String, dynamic>;
    expect(afterLoad['body'], 'body_superhero_male');
    expect(afterLoad['glasses'], isNull);

    // ...and again after a slot swap.
    await tester.tap(find.byKey(const Key('toggleGlassesButton')));
    await tester.pumpAndSettle();

    final afterSwap =
        jsonDecode(repository.stored!.avatarDefinitionJson!) as Map<String, dynamic>;
    expect(afterSwap['glasses'], 'glasses_realistic');
  });

  testWidgets('a persisted definition is loaded instead of the default',
      (tester) async {
    final renderer = _FakeAvatarRenderer();
    final repository = _InMemoryIdentityRepository(_identity(
      avatarDefinitionJson:
          '{"id":"saved","body":"body_placeholder","glasses":"glasses_placeholder"}',
    ));

    await tester.pumpWidget(_screen(renderer, repository));
    await tester.pumpAndSettle();

    expect(renderer.calls, contains('load:saved'));
    expect(renderer.current!.glasses, 'glasses_placeholder');
    // The toggle reflects the restored state rather than defaulting to off.
    expect(find.text('Remove glasses'), findsOneWidget);
  });
}
