import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:store/store.dart';

/// Real purchase verification (StoreKit / Play Billing) is a later
/// milestone; overridden in tests with a fresh [InMemoryEntitlementStore]
/// per test so purchases don't leak between them.
final entitlementStoreProvider = Provider<EntitlementStore>((ref) {
  return InMemoryEntitlementStore();
});

class OwnedCosmeticsNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() {
    return ref.read(entitlementStoreProvider).ownedCosmeticIds();
  }

  Future<void> purchase(String cosmeticId) async {
    final store = ref.read(entitlementStoreProvider);
    await store.grant(cosmeticId);
    state = AsyncData(await store.ownedCosmeticIds());
  }
}

final ownedCosmeticsProvider =
    AsyncNotifierProvider<OwnedCosmeticsNotifier, Set<String>>(OwnedCosmeticsNotifier.new);
