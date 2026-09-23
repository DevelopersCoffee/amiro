/// Tracks which cosmetic ids the current user has purchased.
///
/// Real purchase verification (StoreKit / Play Billing) is a later
/// milestone — see this package's README. `grant` is the seam that a
/// real payments integration will call after a verified purchase.
abstract class EntitlementStore {
  Future<Set<String>> ownedCosmeticIds();
  Future<void> grant(String cosmeticId);
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
}
