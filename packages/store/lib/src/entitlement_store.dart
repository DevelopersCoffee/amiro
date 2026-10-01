/// Tracks which cosmetic ids the current user has purchased.
///
/// `grant` is what a real payments integration calls after a verified
/// purchase (see [RevenueCatEntitlementStore] in this package).
abstract class EntitlementStore {
  Future<Set<String>> ownedCosmeticIds();
  Future<void> grant(String cosmeticId);

  /// Re-attaches purchases the user's store account already owns (after a
  /// reinstall or a new phone). Call [ownedCosmeticIds] afterwards.
  Future<void> restore();
}

/// Thrown by [EntitlementStore.grant] when the user backs out of the
/// native purchase sheet — distinct from a real failure so callers can
/// stay quiet instead of showing an error.
class PurchaseCancelledException implements Exception {
  const PurchaseCancelledException();
}

/// In-process entitlement store. Not persisted across app restarts —
/// a stand-in until real purchase storage lands (identity-linked
/// persistence, alongside `Identity.avatarDefinitionJson`'s pattern).
class InMemoryEntitlementStore implements EntitlementStore {
  final Set<String> _owned = {};

  @override
  Future<Set<String>> ownedCosmeticIds() async => Set.unmodifiable(_owned);

  @override
  Future<void> grant(String cosmeticId) async {
    _owned.add(cosmeticId);
  }

  @override
  Future<void> restore() async {}
}
