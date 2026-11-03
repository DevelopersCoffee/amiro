import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avatar_core/avatar_core.dart';
import 'package:avatar_renderer/avatar_renderer.dart';
import 'package:store/store.dart';

import 'package:amiro_app/avatar/avatar_defaults.dart';
import 'package:amiro_app/avatar/avatar_providers.dart';
import 'package:identity_core/identity_core.dart';
import 'package:amiro_app/identity/identity_providers.dart';
import 'package:amiro_app/store/store_providers.dart';
import 'package:amiro_app/store/store_screen.dart';
import 'package:amiro_app/theme/amiro_theme.dart';

import 'package:amiro_app/avatar/avatar_loader.dart';

import '../avatar/fake_avatar_renderer.dart';
import '../identity/in_memory_identity_repository.dart';
import '../pump_helpers.dart';

/// Matches [_screen]'s default identity (null → male in [resolveAvatarGender]).
AvatarGender _storeTestGender() => resolveAvatarGender(null);

/// [StoreScreen]'s catalog [ListView.separated] builds `2 * rowCount - 1`
/// sliver children (rows plus separators between them).
int _storeCatalogSeparatedChildCount(WidgetTester tester) {
  final listView = tester.widget<ListView>(
    find.descendant(
      of: find.byType(StoreScreen),
      matching: find.byType(ListView),
    ),
  );
  final delegate = listView.childrenDelegate;
  expect(delegate, isA<SliverChildBuilderDelegate>());
  return (delegate as SliverChildBuilderDelegate).childCount!;
}

List<Object> _storeTestRows({Set<String> owned = const {}}) =>
    storeDisplayRows(cosmeticCatalog, owned, _storeTestGender());

Future<void> pumpStoreReady(WidgetTester tester) async {
  await pumpAfterAvatarLoad(tester);
  await pumpShort(tester, frames: 4);
}

Widget _screen(
  AvatarRenderer renderer, {
  EntitlementStore? entitlementStore,
  Identity? identity,
}) {
  return ProviderScope(
    overrides: [
      avatarRendererProvider.overrideWithValue(renderer),
      identityRepositoryProvider.overrideWithValue(
        InMemoryIdentityRepository(identity),
      ),
      if (entitlementStore != null)
        entitlementStoreProvider.overrideWithValue(entitlementStore),
    ],
    child: MaterialApp(
      theme: buildAmiroTheme(loadFonts: false),
      home: const StoreScreen(isActive: true),
    ),
  );
}

void main() {
  setUp(resetAvatarLoadChainForTest);

  group('gender-filtered catalog (literal expectations)', () {
    testWidgets('male identity hides female-fitted hair', (tester) async {
      useStoreListViewport(tester, storeRowCount: 11);
      await tester.pumpWidget(
        _screen(
          FakeAvatarRenderer(),
          identity: const Identity(
            id: 'test',
            displayName: 'Test',
            username: 'test',
            avatarGender: 'male',
          ),
        ),
      );
      await pumpStoreReady(tester);

      expect(find.text('Twin Buns'), findsNothing);
      for (final name in [
        'Classic Frame',
        'Signature Tee',
        'Clean Part',
        'Buzz Cut',
        'Village Tunic',
        'Village Trousers',
        'Leather Boots',
        'Riviera Optics',
        'Long Flow',
        'Full Beard',
      ]) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      expect(find.text('Series #1 · Founders'), findsOneWidget);
      expect(_storeCatalogSeparatedChildCount(tester), 2 * 11 - 1);
    });

    testWidgets('female identity hides male-fitted hair and beards', (
      tester,
    ) async {
      useStoreListViewport(tester, storeRowCount: 9);
      await tester.pumpWidget(
        _screen(
          FakeAvatarRenderer(),
          identity: const Identity(
            id: 'test',
            displayName: 'Test',
            username: 'test',
            avatarGender: 'female',
          ),
        ),
      );
      await pumpStoreReady(tester);

      for (final name in ['Clean Part', 'Buzz Cut', 'Full Beard']) {
        expect(find.text(name), findsNothing, reason: name);
      }
      for (final name in [
        'Classic Frame',
        'Signature Tee',
        'Twin Buns',
        'Village Tunic',
        'Village Trousers',
        'Leather Boots',
        'Riviera Optics',
        'Long Flow',
      ]) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      expect(find.text('Series #1 · Founders'), findsOneWidget);
      expect(_storeCatalogSeparatedChildCount(tester), 2 * 9 - 1);
    });
  });

  testWidgets('lists every catalog item with buy affordance or owned state', (
    tester,
  ) async {
    final rows = _storeTestRows();
    useStoreListViewport(tester, storeRowCount: rows.length);
    final renderer = FakeAvatarRenderer();
    await tester.pumpWidget(_screen(renderer));
    await pumpStoreReady(tester);

    final visibleItems = rows.whereType<CosmeticListing>();
    for (final item in visibleItems) {
      expect(find.text(item.name), findsOneWidget);
    }
    expect(find.text('FREE'), findsNothing);
    for (final item in visibleItems.where((c) => !c.isFree)) {
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
    await pumpStoreReady(tester);

    await tester.tap(find.text('Classic Frame'));
    await pumpShort(tester, frames: 10);

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
      await pumpStoreReady(tester);

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
    await pumpStoreReady(tester);

    expect(
      await entitlements.ownedCosmeticIds(),
      isNot(contains('riviera_optics')),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Buy \$2.99'));
    await pumpShort(tester, frames: 10);

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
      await pumpStoreReady(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Buy \$2.99'));
      await pumpShort(tester, frames: 10);

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
    await pumpStoreReady(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Buy \$2.99'));
    await pumpUntilFound(tester, find.textContaining('Purchase failed'));

    expect(find.textContaining('Purchase failed'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Buy \$2.99'), findsOneWidget);
  });

  testWidgets(
    'Restore purchases re-reads ownership from the store and confirms',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final entitlements = _RestorableEntitlementStore(
        owned: {'riviera_optics'},
      );
      await tester.pumpWidget(
        _screen(FakeAvatarRenderer(), entitlementStore: entitlements),
      );
      await pumpStoreReady(tester);
      // Ownership only becomes visible to the app once restore runs.
      expect(find.widgetWithText(FilledButton, 'Buy \$2.99'), findsOneWidget);

      await tester.tap(find.text('Restore purchases'));
      await pumpUntilFound(tester, find.text('Purchases restored'));

      expect(entitlements.restoreCalls, 1);
      expect(find.widgetWithText(FilledButton, 'Buy \$2.99'), findsNothing);
      expect(find.text('Purchases restored'), findsOneWidget);
    },
  );

  testWidgets('a failed restore says so and leaves the Store usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final entitlements = _RestorableEntitlementStore(
      owned: {'riviera_optics'},
      failRestore: true,
    );
    await tester.pumpWidget(
      _screen(FakeAvatarRenderer(), entitlementStore: entitlements),
    );
    await pumpStoreReady(tester);

    await tester.tap(find.text('Restore purchases'));
    await pumpUntilFound(tester, find.textContaining('Restore failed'));

    expect(find.textContaining('Restore failed'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Buy \$2.99'), findsOneWidget);
  });

  testWidgets('prices use the monospaced tabular style', (tester) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_screen(FakeAvatarRenderer()));
    await pumpStoreReady(tester);

    final price = tester.widget<Text>(find.text('Buy \$2.99'));
    expect(
      price.style?.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  testWidgets(
    'shows each item rarity and groups series items under a numbered header',
    (tester) async {
      final rows = _storeTestRows();
      useStoreListViewport(tester, storeRowCount: rows.length);
      await tester.pumpWidget(_screen(FakeAvatarRenderer()));
      await pumpStoreReady(tester);

      for (final item in rows.whereType<CosmeticListing>()) {
        expect(
          find.textContaining(item.rarity.label),
          findsWidgets,
          reason: item.id,
        );
      }
      final series = rows
          .whereType<CosmeticListing>()
          .firstWhere((c) => c.series != null)
          .series!;
      expect(find.text(series.label), findsOneWidget);
    },
  );

  testWidgets(
    'series items render after unseriesed items, under their header',
    (tester) async {
      final rows = _storeTestRows();
      useStoreListViewport(tester, storeRowCount: rows.length);
      await tester.pumpWidget(_screen(FakeAvatarRenderer()));
      await pumpStoreReady(tester);

      final series = rows
          .whereType<CosmeticListing>()
          .firstWhere((c) => c.series != null)
          .series!;
      final headerY = tester.getTopLeft(find.text(series.label)).dy;
      for (final item in rows.whereType<CosmeticListing>()) {
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
      await pumpStoreReady(tester);

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
    await pumpStoreReady(tester);

    final before = collectionProgress(cosmeticCatalog, const {}).first;
    final buy = find.widgetWithText(FilledButton, 'Buy \$2.99');
    await tester.tap(buy);
    await pumpShort(tester, frames: 10);

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
    await pumpStoreReady(tester);

    expect(find.text('Complete'), findsOneWidget);
    expect(find.textContaining(' / '), findsNothing);
  });

  group('cosmetic card treatment (DESIGN.md)', () {
    testWidgets(
      'an equipped item gets a brass selection bar and an EQUIPPED badge',
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
        await pumpStoreReady(tester);

        expect(find.text('EQUIPPED'), findsOneWidget);
        expect(
          find.descendant(
            of: find.ancestor(
              of: find.text('Classic Frame'),
              matching: find.byType(InkWell),
            ),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is ColoredBox &&
                  w.color == AmiroColors.primary &&
                  w.child is SizedBox &&
                  (w.child as SizedBox).width == 3,
            ),
          ),
          findsOneWidget,
        );
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
        await pumpStoreReady(tester);

        expect(
          find.descendant(
            of: find.ancestor(
              of: find.text('Riviera Optics'),
              matching: find.byType(InkWell),
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
      'an item that is not equipped has no badge and no brass selection bar',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_screen(FakeAvatarRenderer()));
        await pumpStoreReady(tester);

        // Classic Frame's asset (glasses_placeholder) is never in the
        // default avatar, unlike the default outfit's free items — so it is
        // always unequipped regardless of what else the default fits.
        expect(
          find.descendant(
            of: find.ancestor(
              of: find.text('Classic Frame'),
              matching: find.byType(InkWell),
            ),
            matching: find.text('EQUIPPED'),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.ancestor(
              of: find.text('Classic Frame'),
              matching: find.byType(InkWell),
            ),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is ColoredBox &&
                  w.color == AmiroColors.primary &&
                  w.child is SizedBox &&
                  (w.child as SizedBox).width == 3,
            ),
          ),
          findsNothing,
        );
      },
    );

    testWidgets('each catalog row is a tappable boutique card, not a list tile', (
      tester,
    ) async {
      final rows = _storeTestRows();
      useStoreListViewport(tester, storeRowCount: rows.length);
      await tester.pumpWidget(_screen(FakeAvatarRenderer()));
      await pumpStoreReady(tester);

      expect(find.byType(InkWell), findsWidgets);
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

  @override
  Future<void> restore() async {}
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

  @override
  Future<void> restore() async {}
}

/// Models a store whose purchases only surface after an explicit restore,
/// like a fresh install before RevenueCat has synced.
class _RestorableEntitlementStore implements EntitlementStore {
  final Set<String> _remote;
  final bool failRestore;
  final Set<String> _visible = {};
  int restoreCalls = 0;

  _RestorableEntitlementStore({
    required Set<String> owned,
    this.failRestore = false,
  }) : _remote = owned;

  @override
  Future<Set<String>> ownedCosmeticIds() async => Set.unmodifiable(_visible);

  @override
  Future<void> grant(String cosmeticId) async {}

  @override
  Future<void> restore() async {
    restoreCalls++;
    if (failRestore) throw Exception('billing unavailable');
    _visible.addAll(_remote);
  }
}
