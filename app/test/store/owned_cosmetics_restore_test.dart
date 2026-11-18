import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:identity_core/identity_core.dart';
import 'package:store/store.dart';

import 'package:amiro_app/identity/identity_providers.dart';
import 'package:amiro_app/store/store_providers.dart';

import '../identity/in_memory_identity_repository.dart';

class _RecordingRestoreStore implements EntitlementStore {
  final RestoreOutcome outcome;
  final Set<String> owned;
  int restoreCalls = 0;
  String? lastBoundIdentity;

  _RecordingRestoreStore({
    required this.outcome,
    this.owned = const {},
  });

  @override
  Future<Set<String>> ownedCosmeticIds() async => owned;

  @override
  Future<void> grant(String cosmeticId) async {}

  @override
  Future<RestoreOutcome> restore() async {
    restoreCalls++;
    return outcome;
  }
}

Future<void> _pumpScope(
  WidgetTester tester, {
  required EntitlementStore store,
  Identity? identity,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        identityRepositoryProvider.overrideWithValue(
          InMemoryIdentityRepository(identity),
        ),
        entitlementStoreProvider.overrideWithValue(store),
      ],
      child: const SizedBox.shrink(),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets(
    'restore binds RevenueCat to the current Amiro identity id',
    (tester) async {
      final rcStore = RevenueCatEntitlementStore(isAndroid: false);
      const identity = Identity(
        id: 'identity-52',
        displayName: 'A',
        username: 'a',
      );
      await _pumpScope(tester, store: rcStore, identity: identity);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(SizedBox)),
      );
      await container.read(ownedCosmeticsProvider.notifier).restore();
      await tester.pump();

      expect(rcStore.boundAmiroIdentityId, 'identity-52');
    },
  );

  testWidgets('restore returns outcome to callers', (tester) async {
    final fake = _RecordingRestoreStore(
      outcome: const RestoreOutcome.restored({'long_flow'}),
      owned: {'long_flow'},
    );
    await _pumpScope(
      tester,
      store: fake,
      identity: const Identity(id: 'x', displayName: 'X', username: 'x'),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SizedBox)),
    );

    final outcome =
        await container.read(ownedCosmeticsProvider.notifier).restore();
    expect(outcome, isA<RestoreHadPurchases>());
    expect(fake.restoreCalls, 1);
    expect(container.read(ownedCosmeticsProvider).value, {'long_flow'});
  });
}