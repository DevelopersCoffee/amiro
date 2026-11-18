import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:store/store.dart';

import '../identity/identity_providers.dart' show identityRepositoryProvider;
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
    if (!ref.read(revenueCatActivatedProvider)) {
      return const {};
    }
    return ref.read(entitlementStoreProvider).ownedCosmeticIds();
  }

  Future<void> _activateRevenueCat() async {
    ref.read(revenueCatActivatedProvider.notifier).activate();
    final identity = await ref.read(identityRepositoryProvider).getCurrent();
    final identityId = identity?.id;
    if (identityId == null) return;
    final store = ref.read(entitlementStoreProvider);
    if (store is RevenueCatEntitlementStore) {
      await store.bindAmiroIdentity(identityId);
    }
  }

  Future<void> ensureLoaded() async {
    await _activateRevenueCat();
    state = const AsyncLoading();
    state = AsyncData(
      await ref.read(entitlementStoreProvider).ownedCosmeticIds(),
    );
  }

  /// Asks the store account for existing purchases, then refreshes what
  /// the app shows as owned.
  Future<RestoreOutcome> restore() async {
    await _activateRevenueCat();
    final store = ref.read(entitlementStoreProvider);
    final outcome = await store.restore();
    state = AsyncData(await store.ownedCosmeticIds());
    return outcome;
  }

  Future<void> purchase(String cosmeticId) async {
    await _activateRevenueCat();
    final store = ref.read(entitlementStoreProvider);
    await store.grant(cosmeticId);
    state = AsyncData(await store.ownedCosmeticIds());
  }
}

final ownedCosmeticsProvider =
    AsyncNotifierProvider<OwnedCosmeticsNotifier, Set<String>>(
      OwnedCosmeticsNotifier.new,
    );
