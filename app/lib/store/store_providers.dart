import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:store/store.dart';

import 'revenue_cat_activation.dart';

/// Real purchases go through RevenueCat/Play Billing; overridden in tests
/// with a fresh [InMemoryEntitlementStore] per test so purchases don't
/// leak between them.
final entitlementStoreProvider = Provider<EntitlementStore>((ref) {
  return RevenueCatEntitlementStore();
});

class OwnedCosmeticsNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    ref.listen(revenueCatActivatedProvider, (previous, next) {
      if (next && previous != next) {
        ref.invalidateSelf();
      }
    });
    if (!ref.read(revenueCatActivatedProvider)) {
      return const {};
    }
    return ref.read(entitlementStoreProvider).ownedCosmeticIds();
  }

  Future<void> ensureLoaded() async {
    ref.read(revenueCatActivatedProvider.notifier).activate();
    state = const AsyncLoading();
    state = AsyncData(
      await ref.read(entitlementStoreProvider).ownedCosmeticIds(),
    );
  }

  /// Asks the store account for existing purchases, then refreshes what
  /// the app shows as owned.
  Future<void> restore() async {
    ref.read(revenueCatActivatedProvider.notifier).activate();
    final store = ref.read(entitlementStoreProvider);
    await store.restore();
    state = AsyncData(await store.ownedCosmeticIds());
  }

  Future<void> purchase(String cosmeticId) async {
    ref.read(revenueCatActivatedProvider.notifier).activate();
    final store = ref.read(entitlementStoreProvider);
    await store.grant(cosmeticId);
    state = AsyncData(await store.ownedCosmeticIds());
  }
}

final ownedCosmeticsProvider =
    AsyncNotifierProvider<OwnedCosmeticsNotifier, Set<String>>(
      OwnedCosmeticsNotifier.new,
    );
