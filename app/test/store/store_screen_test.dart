import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avatar_core/avatar_core.dart';
import 'package:avatar_renderer/avatar_renderer.dart';
import 'package:store/store.dart';

import 'package:amiro_app/avatar/avatar_providers.dart';
import 'package:amiro_app/identity/identity_providers.dart';
import 'package:amiro_app/store/store_providers.dart';
import 'package:amiro_app/store/store_screen.dart';
import 'package:amiro_app/theme/amiro_card.dart';
import 'package:amiro_app/theme/amiro_theme.dart';

import '../avatar/fake_avatar_renderer.dart';
import '../identity/in_memory_identity_repository.dart';

Widget _screen(AvatarRenderer renderer, {EntitlementStore? entitlementStore}) {
  return ProviderScope(
    overrides: [
      avatarRendererProvider.overrideWithValue(renderer),
      identityRepositoryProvider.overrideWithValue(
        InMemoryIdentityRepository(),
      ),
      if (entitlementStore != null)
        entitlementStoreProvider.overrideWithValue(entitlementStore),
    ],
    child: MaterialApp(
      theme: buildAmiroTheme(loadFonts: false),
      home: const StoreScreen(),
    ),
  );
}

void main() {
  testWidgets('lists every catalog item with its price or FREE', (
    tester,
  ) async {
    // Tall enough that the lazily-built list renders every catalog row.
    tester.view.physicalSize = const Size(800, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final renderer = FakeAvatarRenderer();
    await tester.pumpWidget(_screen(renderer));
    await tester.pumpAndSettle();

    for (final item in cosmeticCatalog) {
      expect(find.text(item.name), findsOneWidget);
    }
    expect(find.text('FREE'), findsNWidgets(7));
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

  testWidgets(
    'a priced item not yet owned shows a Buy button, not a preview-only state',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final renderer = FakeAvatarRenderer();
      await tester.pumpWidget(_screen(renderer));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Buy \$2.99'), findsOneWidget);
    },
  );

  testWidgets('buying a priced item grants it and the Buy button disappears', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final renderer = FakeAvatarRenderer();
    final entitlements = InMemoryEntitlementStore();
    await tester.pumpWidget(_screen(renderer, entitlementStore: entitlements));
    await tester.pumpAndSettle();

    expect(
      await entitlements.ownedCosmeticIds(),
      isNot(contains('riviera_optics')),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Buy \$2.99'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Buy \$2.99'), findsNothing);
    expect(await entitlements.ownedCosmeticIds(), contains('riviera_optics'));
  });

  testWidgets(
    'backing out of the native purchase sheet does not grant the item or '
    'show an error',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final renderer = FakeAvatarRenderer();
      final entitlements = _CancellingEntitlementStore();
      await tester.pumpWidget(
        _screen(renderer, entitlementStore: entitlements),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Buy \$2.99'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Buy \$2.99'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(
        await entitlements.ownedCosmeticIds(),
        isNot(contains('riviera_optics')),
      );
    },
  );

  testWidgets('a purchase failure surfaces an error, not a silent no-op', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final renderer = FakeAvatarRenderer();
    final entitlements = _FailingEntitlementStore();
    await tester.pumpWidget(_screen(renderer, entitlementStore: entitlements));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Buy \$2.99'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Purchase failed'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Buy \$2.99'), findsOneWidget);
  });

  testWidgets('prices use the monospaced tabular style', (tester) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_screen(FakeAvatarRenderer()));
    await tester.pumpAndSettle();

    final price = tester.widget<Text>(find.text('Buy \$2.99'));
    expect(
      price.style?.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  testWidgets(
    'shows each item rarity and groups series items under a numbered header',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_screen(FakeAvatarRenderer()));
      await tester.pumpAndSettle();

      for (final item in cosmeticCatalog) {
        expect(
          find.textContaining(item.rarity.label),
          findsWidgets,
          reason: item.id,
        );
      }
      final series = cosmeticCatalog
          .firstWhere((c) => c.series != null)
          .series!;
      expect(find.text(series.label), findsOneWidget);
    },
  );

  testWidgets(
    'series items render after unseriesed items, under their header',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_screen(FakeAvatarRenderer()));
      await tester.pumpAndSettle();

      final series = cosmeticCatalog
          .firstWhere((c) => c.series != null)
          .series!;
      final headerY = tester.getTopLeft(find.text(series.label)).dy;
      for (final item in cosmeticCatalog) {
        final y = tester.getTopLeft(find.text(item.name)).dy;
        if (item.series == null) {
          expect(y, lessThan(headerY), reason: item.id);
        } else {
          expect(y, greaterThan(headerY), reason: item.id);
        }
      }
    },
  );

  testWidgets(
    'a series header shows collection progress out of the series total',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_screen(FakeAvatarRenderer()));
      await tester.pumpAndSettle();

      final progress = collectionProgress(cosmeticCatalog, const {}).first;
      expect(
        find.text('${progress.owned} / ${progress.total}'),
        findsOneWidget,
      );
      expect(find.text('Complete'), findsNothing);
    },
  );

  testWidgets('progress advances on purchase', (tester) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _screen(
        FakeAvatarRenderer(),
        entitlementStore: InMemoryEntitlementStore(),
      ),
    );
    await tester.pumpAndSettle();

    final before = collectionProgress(cosmeticCatalog, const {}).first;
    final buy = find.widgetWithText(FilledButton, 'Buy \$2.99');
    await tester.tap(buy);
    await tester.pumpAndSettle();

    expect(find.text('${before.owned + 1} / ${before.total}'), findsOneWidget);
  });

  testWidgets('a fully owned series shows Complete', (tester) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final entitlements = InMemoryEntitlementStore();
    for (final item in cosmeticCatalog.where((c) => c.series != null)) {
      await entitlements.grant(item.id);
    }
    await tester.pumpWidget(
      _screen(FakeAvatarRenderer(), entitlementStore: entitlements),
    );
    await tester.pumpAndSettle();

    expect(find.text('Complete'), findsOneWidget);
    expect(find.textContaining(' / '), findsNothing);
  });

  group('cosmetic card treatment (DESIGN.md)', () {
    testWidgets(
      'an equipped item gets a 2px brass border and an EQUIPPED badge',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        final renderer = FakeAvatarRenderer();
        await renderer.load(
          const AvatarDefinition(
            id: 'default',
            body: 'body_superhero_male',
            glasses: 'glasses_placeholder',
          ),
        );
        await tester.pumpWidget(_screen(renderer));
        await tester.pumpAndSettle();

        expect(find.text('EQUIPPED'), findsOneWidget);
        final card = tester.widget<Container>(
          find
              .descendant(
                of: find.ancestor(
                  of: find.text('EQUIPPED'),
                  matching: find.byType(AmiroCard),
                ),
                matching: find.byType(Container),
              )
              .first,
        );
        final border = (card.decoration as BoxDecoration).border! as Border;
        expect(border.top.width, 2);
        expect(border.top.color, AmiroColors.primary);
      },
    );

    testWidgets(
      'an equipped, unowned item keeps its name on one line at phone width',
      (tester) async {
        // The EQUIPPED badge and the Buy button used to share the name's
        // row and squeeze it to one letter per line. 560 is the phone-width
        // equivalent for the test font, whose glyphs are much wider than
        // the real typeface: the name fits on one line only if it has the
        // row to itself.
        tester.view.physicalSize = const Size(560, 4000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        final renderer = FakeAvatarRenderer();
        await renderer.load(
          const AvatarDefinition(
            id: 'default',
            body: 'body_superhero_male',
            glasses: 'glasses_realistic',
          ),
        );
        await tester.pumpWidget(_screen(renderer));
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.ancestor(
              of: find.text('Riviera Optics'),
              matching: find.byType(AmiroCard),
            ),
            matching: find.text('EQUIPPED'),
          ),
          findsOneWidget,
        );
        expect(find.widgetWithText(FilledButton, 'Buy \$2.99'), findsOneWidget);
        expect(
          tester.getSize(find.text('Riviera Optics')).height,
          tester.getSize(find.text('Classic Frame')).height,
        );
      },
    );

    testWidgets(
      'an item that is not equipped has no badge and the neutral hairline border',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_screen(FakeAvatarRenderer()));
        await tester.pumpAndSettle();

        // Classic Frame's asset (glasses_placeholder) is never in the
        // default avatar, unlike the default outfit's free items — so it is
        // always unequipped regardless of what else the default fits.
        expect(
          find.descendant(
            of: find.ancestor(
              of: find.text('Classic Frame'),
              matching: find.byType(AmiroCard),
            ),
            matching: find.text('EQUIPPED'),
          ),
          findsNothing,
        );
        final card = tester.widget<Container>(
          find
              .descendant(
                of: find.ancestor(
                  of: find.text('Classic Frame'),
                  matching: find.byType(AmiroCard),
                ),
                matching: find.byType(Container),
              )
              .first,
        );
        final border = (card.decoration as BoxDecoration).border! as Border;
        expect(border.top.width, 1);
        expect(border.top.color, AmiroColors.surfaceBorder);
      },
    );

    testWidgets('each catalog row is an AmiroCard, not a flat list tile', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 3600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_screen(FakeAvatarRenderer()));
      await tester.pumpAndSettle();

      expect(find.byType(AmiroCard), findsNWidgets(cosmeticCatalog.length));
      expect(find.byType(ListTile), findsNothing);
    });
  });
}

/// Simulates the user backing out of the native Play Billing sheet.
class _CancellingEntitlementStore implements EntitlementStore {
  final Set<String> _owned = {};

  @override
  Future<Set<String>> ownedCosmeticIds() async => Set.unmodifiable(_owned);

  @override
  Future<void> grant(String cosmeticId) {
    throw const PurchaseCancelledException();
  }
}

/// Simulates a real purchase failure (network error, billing unavailable).
class _FailingEntitlementStore implements EntitlementStore {
  final Set<String> _owned = {};

  @override
  Future<Set<String>> ownedCosmeticIds() async => Set.unmodifiable(_owned);

  @override
  Future<void> grant(String cosmeticId) {
    throw Exception('billing unavailable');
  }
}
