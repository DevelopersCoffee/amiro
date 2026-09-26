import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avatar_renderer/avatar_renderer.dart';
import 'package:identity_core/identity_core.dart';

import 'package:amiro_app/avatar/avatar_providers.dart';
import 'package:amiro_app/avatar/avatar_screen.dart';
import 'package:amiro_app/identity/identity_providers.dart';

import 'package:avatar_core/avatar_core.dart';

import 'fake_avatar_renderer.dart';
import '../identity/in_memory_identity_repository.dart';

/// Wraps [FakeAvatarRenderer] so [load] doesn't resolve until [gate]
/// completes — lets a test observe UI while the load is still in flight.
class _GatedLoadRenderer implements AvatarRenderer {
  final FakeAvatarRenderer _inner = FakeAvatarRenderer();
  final Future<void> gate;

  _GatedLoadRenderer(this.gate);

  @override
  AvatarDefinition? get current => _inner.current;

  List<String> get calls => _inner.calls;

  @override
  Future<void> load(AvatarDefinition definition) async {
    await gate;
    await _inner.load(definition);
  }

  @override
  Widget buildView() => _inner.buildView();

  @override
  Future<void> updateSlot(String slot, String? assetId) =>
      _inner.updateSlot(slot, assetId);

  @override
  Future<void> dispose() => _inner.dispose();
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

void main() {
  testWidgets(
    'avatar screen loads the definition on start and renders a view',
    (tester) async {
      final renderer = FakeAvatarRenderer();

      await tester.pumpWidget(_screen(renderer, InMemoryIdentityRepository()));
      await tester.pumpAndSettle();

      expect(renderer.calls, contains('load:default'));
      // MaterialApp's default route transition also builds a transient,
      // transparent ColoredBox as part of its FadeTransition/SlideTransition
      // chain, so match on the fake renderer's own grey ColoredBox rather than
      // any ColoredBox in the tree.
      expect(
        find.byWidgetPredicate(
          (widget) => widget is ColoredBox && widget.color == Colors.grey,
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('tapping the glasses toggle swaps that slot', (tester) async {
    final renderer = FakeAvatarRenderer();

    await tester.pumpWidget(_screen(renderer, InMemoryIdentityRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('toggleGlassesButton')));
    await tester.pumpAndSettle();

    expect(renderer.calls, contains('updateSlot:glasses:glasses_realistic'));
    expect(renderer.current!.glasses, 'glasses_realistic');
  });

  testWidgets('tapping again removes the glasses', (tester) async {
    final renderer = FakeAvatarRenderer();

    await tester.pumpWidget(_screen(renderer, InMemoryIdentityRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('toggleGlassesButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('toggleGlassesButton')));
    await tester.pumpAndSettle();

    expect(renderer.current!.glasses, isNull);
  });

  testWidgets(
    'the rendered definition is persisted onto the current identity',
    (tester) async {
      final renderer = FakeAvatarRenderer();
      final repository = InMemoryIdentityRepository(_identity());

      await tester.pumpWidget(_screen(renderer, repository));
      await tester.pumpAndSettle();

      // Persisted after the initial load...
      final afterLoad =
          jsonDecode(repository.stored!.avatarDefinitionJson!)
              as Map<String, dynamic>;
      expect(afterLoad['body'], 'body_superhero_male');
      expect(afterLoad['glasses'], isNull);

      // ...and again after a slot swap.
      await tester.tap(find.byKey(const Key('toggleGlassesButton')));
      await tester.pumpAndSettle();

      final afterSwap =
          jsonDecode(repository.stored!.avatarDefinitionJson!)
              as Map<String, dynamic>;
      expect(afterSwap['glasses'], 'glasses_realistic');
    },
  );

  testWidgets('a persisted definition is loaded instead of the default', (
    tester,
  ) async {
    final renderer = FakeAvatarRenderer();
    final repository = InMemoryIdentityRepository(
      _identity(
        avatarDefinitionJson:
            '{"id":"saved","body":"body_placeholder","glasses":"glasses_placeholder"}',
      ),
    );

    await tester.pumpWidget(_screen(renderer, repository));
    await tester.pumpAndSettle();

    expect(renderer.calls, contains('load:saved'));
    expect(renderer.current!.glasses, 'glasses_placeholder');
    // The toggle reflects the restored state rather than defaulting to off.
    expect(find.text('Remove glasses'), findsOneWidget);
  });

  testWidgets('shows the equipped avatar valuation, updating when it changes', (
    tester,
  ) async {
    final renderer = FakeAvatarRenderer();

    await tester.pumpWidget(_screen(renderer, InMemoryIdentityRepository()));
    await tester.pumpAndSettle();

    // Nothing priced equipped yet (default has no glasses).
    expect(find.text('\$0.00'), findsOneWidget);

    // Equips 'glasses_realistic', which the store catalog prices at \$2.99.
    await tester.tap(find.byKey(const Key('toggleGlassesButton')));
    await tester.pumpAndSettle();

    expect(find.text('\$2.99'), findsOneWidget);
  });

  testWidgets('shows the highest equipped rarity next to the valuation', (
    tester,
  ) async {
    final renderer = FakeAvatarRenderer();

    await tester.pumpWidget(_screen(renderer, InMemoryIdentityRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Rare'), findsNothing);

    // 'glasses_realistic' is Riviera Optics, a Rare listing.
    await tester.tap(find.byKey(const Key('toggleGlassesButton')));
    await tester.pumpAndSettle();

    expect(find.text('Rare'), findsOneWidget);
  });

  testWidgets(
    'shows a branded loading state until the avatar finishes loading',
    (tester) async {
      final gate = Completer<void>();
      final renderer = _GatedLoadRenderer(gate.future);

      await tester.pumpWidget(_screen(renderer, InMemoryIdentityRepository()));
      await tester.pump();

      expect(find.text('Waking up your Amiro…'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is ColoredBox && widget.color == Colors.grey,
        ),
        findsNothing,
      );

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('Waking up your Amiro…'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is ColoredBox && widget.color == Colors.grey,
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'plays a reveal ceremony on first-ever avatar creation, chrome after',
    (tester) async {
      final renderer = FakeAvatarRenderer();

      await tester.pumpWidget(_screen(renderer, InMemoryIdentityRepository()));
      await tester.pump(); // load resolves, reveal animation starts

      // Chrome (the equip control) hasn't appeared yet — the avatar itself is
      // still materializing.
      expect(find.byKey(const Key('toggleGlassesButton')), findsNothing);

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('toggleGlassesButton')), findsOneWidget);
    },
  );

  testWidgets(
    'skips the reveal ceremony for a returning user with a saved avatar',
    (tester) async {
      final renderer = FakeAvatarRenderer();
      final repository = InMemoryIdentityRepository(
        _identity(
          avatarDefinitionJson: '{"id":"saved","body":"body_placeholder"}',
        ),
      );

      await tester.pumpWidget(_screen(renderer, repository));
      await tester.pump(); // load resolves

      // No ceremony to wait out — chrome is there right away.
      expect(find.byKey(const Key('toggleGlassesButton')), findsOneWidget);
    },
  );
}
