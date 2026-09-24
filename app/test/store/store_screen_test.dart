import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avatar_renderer/avatar_renderer.dart';
import 'package:store/store.dart';

import 'package:amiro_app/avatar/avatar_providers.dart';
import 'package:amiro_app/identity/identity_providers.dart';
import 'package:amiro_app/store/store_providers.dart';
import 'package:amiro_app/store/store_screen.dart';

import '../avatar/fake_avatar_renderer.dart';
import '../identity/in_memory_identity_repository.dart';

Widget _screen(AvatarRenderer renderer, {EntitlementStore? entitlementStore}) {
  return ProviderScope(
    overrides: [
      avatarRendererProvider.overrideWithValue(renderer),
      identityRepositoryProvider.overrideWithValue(InMemoryIdentityRepository()),
      if (entitlementStore != null) entitlementStoreProvider.overrideWithValue(entitlementStore),
    ],
    child: const MaterialApp(home: StoreScreen()),
  );
}

void main() {
  testWidgets('lists every catalog item with its price or FREE', (tester) async {
    // Tall enough that the lazily-built list renders every catalog row.
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final renderer = FakeAvatarRenderer();
    await tester.pumpWidget(_screen(renderer));
    await tester.pumpAndSettle();

    for (final item in cosmeticCatalog) {
      expect(find.text(item.name), findsOneWidget);
    }
    expect(find.text('FREE'), findsNWidgets(4));
    for (final item in cosmeticCatalog.where((c) => !c.isFree)) {
      expect(
        find.widgetWithText(
          FilledButton,
          'Buy \$${(item.priceCents / 100).toStringAsFixed(2)}',
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('tapping a free item previews it on the avatar', (tester) async {
    final renderer = FakeAvatarRenderer();
    await tester.pumpWidget(_screen(renderer));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Classic Frame'));
    await tester.pumpAndSettle();

    expect(renderer.calls, contains('updateSlot:glasses:glasses_placeholder'));
  });

  testWidgets('a priced item not yet owned shows a Buy button, not a preview-only state',
      (tester) async {
    final renderer = FakeAvatarRenderer();
    await tester.pumpWidget(_screen(renderer));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Buy \$2.99'), findsOneWidget);
  });

  testWidgets('buying a priced item grants it and the Buy button disappears', (tester) async {
    final renderer = FakeAvatarRenderer();
    final entitlements = InMemoryEntitlementStore();
    await tester.pumpWidget(_screen(renderer, entitlementStore: entitlements));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Buy \$2.99'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Buy \$2.99'), findsNothing);
    expect(await entitlements.ownedCosmeticIds(), contains('riviera_optics'));
  });
}
