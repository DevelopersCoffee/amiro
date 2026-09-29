import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:store/store.dart';

/// Real purchases go through RevenueCat/Play Billing; overridden in tests
/// with a fresh [InMemoryEntitlementStore] per test so purchases don't
/// leak between them.
final entitlementStoreProvider = Provider<EntitlementStore>((ref) {
  return RevenueCatEntitlementStore();
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
    AsyncNotifierProvider<OwnedCosmeticsNotifier, Set<String>>(
      OwnedCosmeticsNotifier.new,
    );
