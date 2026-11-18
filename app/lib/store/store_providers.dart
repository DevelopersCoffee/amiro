import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:identity_core/identity_core.dart';

import 'package:store/store.dart';

import '../analytics/analytics_funnel.dart';
import '../identity/identity_providers.dart';
import 'revenue_cat_activation.dart';

/// Real purchases go through RevenueCat/Play Billing; overridden in tests
/// with a fresh [InMemoryEntitlementStore] per test so purchases don't
/// leak between them.
final entitlementStoreProvider = Provider<EntitlementStore>((ref) {
  return RevenueCatEntitlementStore();
});

class OwnedCosmeticsNotifier extends AsyncNotifier<Set<String>> {
  bool _disposed = false;

  @override
  Future<Set<String>> build() async {
    ref.onDispose(() => _disposed = true);
    ref.listen<AsyncValue<Identity?>>(
      currentIdentityProvider,
      (previous, next) {
        final prevId = previous?.valueOrNull?.id;
        final nextId = next.valueOrNull?.id;
        if (prevId == nextId) return;
        // Only react to explicit identity switches (not the first resolution).
        if (prevId == null && nextId != null) return;
        unawaited(_reactToIdentityChange(next.valueOrNull));
      },
    );

    if (!ref.read(revenueCatActivatedProvider)) {
      return const {};
    }
    return ref.read(entitlementStoreProvider).ownedCosmeticIds();
  }

  Future<void> _reactToIdentityChange(Identity? identity) async {
    if (_disposed) return;
    state = const AsyncData({});

    final store = ref.read(entitlementStoreProvider);
    try {
      if (store is RevenueCatEntitlementStore) {
        if (identity == null) {
          await store.logOutAmiroIdentity();
          if (_disposed) return;
          ref.read(revenueCatActivatedProvider.notifier).deactivate();
        } else {
          await store.bindAmiroIdentity(identity.id);
        }
      }
    } catch (_) {
      if (_disposed) return;
      ref.read(revenueCatActivatedProvider.notifier).deactivate();
      state = const AsyncData({});
      return;
    }

    if (_disposed) return;
    if (identity != null && ref.read(revenueCatActivatedProvider)) {
      try {
        state = AsyncData(
          await ref.read(entitlementStoreProvider).ownedCosmeticIds(),
        );
      } on RevenueCatIdentityRequiredException {
        state = const AsyncData({});
      } on RevenueCatOfflineException {
        state = const AsyncData({});
      } catch (_) {
        state = const AsyncData({});
      }
    }
  }

  Future<void> _activateRevenueCat() async {
    ref.read(revenueCatActivatedProvider.notifier).activate();
    final identity = await ref.read(identityRepositoryProvider).getCurrent();
    final identityId = identity?.id;
    if (identityId == null || identityId.isEmpty) {
      throw const RevenueCatIdentityRequiredException();
    }
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
    unawaited(ref.read(analyticsFunnelProvider).tryPurchase(cosmeticId));
  }
}

final ownedCosmeticsProvider =
    AsyncNotifierProvider<OwnedCosmeticsNotifier, Set<String>>(
      OwnedCosmeticsNotifier.new,
    );