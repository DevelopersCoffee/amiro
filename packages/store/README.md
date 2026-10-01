# store

Owns the cosmetic catalog, entitlement records, and avatar valuation math.

- `CosmeticListing` / `cosmeticCatalog` — the store's fixed catalog. Scoped to
  the `.glb` assets that exist in `packages/avatar_renderer/assets/cosmetics/`
  today; add a listing here only once its asset exists.
- `EntitlementStore` — tracks which cosmetic ids the current user owns.
  `RevenueCatEntitlementStore` is the real one: it is
  `entitlementStoreProvider`'s default, and `main.dart` must not override
  it. `InMemoryEntitlementStore` is a fake for widget tests only.
- `avatarValuationCents` — sums the catalog price of whatever's equipped on
  an `AvatarDefinition`.

**Purchases are real.** `RevenueCatEntitlementStore.grant` opens the Play
Billing purchase sheet through RevenueCat, and ownership is read from
RevenueCat's active entitlements — platform-native purchase APIs only, no
custom payment system, per the PRD's Monetization section. iOS has no
store credentials yet, so it reports nothing owned and refuses purchases.
