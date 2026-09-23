# store

Owns the cosmetic catalog, entitlement records, and avatar valuation math.

- `CosmeticListing` / `cosmeticCatalog` — the store's fixed catalog. Scoped to
  the `.glb` assets that exist in `packages/avatar_renderer/assets/cosmetics/`
  today; add a listing here only once its asset exists.
- `EntitlementStore` — tracks which cosmetic ids the current user owns.
  `FileEntitlementStore` (used in the real app, wired in `main.dart`)
  persists owned ids as a JSON file in the app's support directory.
  `InMemoryEntitlementStore` is the test/default fallback (used by
  `entitlementStoreProvider`'s default and in widget tests) — it does not
  survive app restarts, which is fine for a fake but is never what
  `main.dart` actually uses.
- `avatarValuationCents` — sums the catalog price of whatever's equipped on
  an `AvatarDefinition`.

**Purchases are stubbed, not real.** `EntitlementStore.grant` is the seam a
real payments integration calls after a verified purchase — platform-native
purchase APIs only (StoreKit / Play Billing), no custom payment system, per
the PRD's Monetization section. No money moves today.
