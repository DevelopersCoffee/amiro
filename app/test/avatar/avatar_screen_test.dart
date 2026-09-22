import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avatar_core/avatar_core.dart';
import 'package:avatar_renderer/avatar_renderer.dart';

import 'package:amiro_app/avatar/avatar_providers.dart';
import 'package:amiro_app/avatar/avatar_screen.dart';

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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [avatarRendererProvider.overrideWithValue(renderer)],
        child: const MaterialApp(home: AvatarScreen()),
      ),
    );
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [avatarRendererProvider.overrideWithValue(renderer)],
        child: const MaterialApp(home: AvatarScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('toggleGlassesButton')));
    await tester.pumpAndSettle();

    expect(renderer.calls, contains('updateSlot:glasses:glasses_placeholder'));
    expect(renderer.current!.glasses, 'glasses_placeholder');
  });

  testWidgets('tapping again removes the glasses', (tester) async {
    final renderer = _FakeAvatarRenderer();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [avatarRendererProvider.overrideWithValue(renderer)],
        child: const MaterialApp(home: AvatarScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('toggleGlassesButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('toggleGlassesButton')));
    await tester.pumpAndSettle();

    expect(renderer.current!.glasses, isNull);
  });
}
